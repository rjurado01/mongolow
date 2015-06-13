# encoding: utf-8

module Mongolow
  module Model
    module ClassMethods
      ##
      # Returns model fields
      # When new initialize is created new instance variable is added for each field
      #
      def fields
        @fields || []
      end

      ##
      # Adds new field to model (instance variable)
      # Model has initials fields:
      #   > _id: document id
      #   > _erros: save validations erros
      #
      # @param: name [string/symbol] field name
      #
      def field(name)
        unless @fields.include? name
          @fields.push name.to_s
        end
      end

      ##
      # Returns collection name for model used in Mongodb
      #
      def coll_name
        self.name.split('::').last.split(/(?=[A-Z])/).map{|x| x.downcase}.join('_')
      end

      ##
      # Selects documents and returns a cursor to the selected documents
      #
      # @param: query [hash]
      #
      def find(query={})
        Mongolow::Cursor.new(self, Driver.client[coll_name].find(query))
      end

      ##
      # Find model by id
      #
      # @param: id [string/BSON::ObjectId]
      #
      def find_by_id(id)
        unless id.class == BSON::ObjectId
          if BSON::ObjectId.legal? id
            id = BSON::ObjectId.from_string(id)
          else
            nil
          end
        end

        find('_id' => id).first
      end

      ##
      # Returns the number of documents
      #
      def count
        Driver.client[coll_name].find.count
      end

      ##
      # Returns the first document
      #
      # @param: query [hash]
      #
      def first(query={})
        self.new(Driver.client[coll_name].find(query).first)
      end

      ##
      # Removes all documents
      #
      def destroy_all
        Driver.client[coll_name].drop
      end

      ##
      # Removes model
      # Returns true if model is removed, false otherwise
      #
      # @param: id [string/BSON::ObjectId]
      #
      def destroy_by_id(id)
        unless id.class == BSON::ObjectId
          if BSON::ObjectId.legal? id
            id = BSON::ObjectId.from_string(id)
          else
            return false
          end
        end

        if model = find('_id' => id).first
          model.run_hook :before_destroy
          model.destroy
          model.run_hook :after_destroy
          true
        else
          false
        end
      end
    end

    ##
    # Adds class methods and hooks
    #
    def self.included(base)
      base.instance_variable_set(:@fields, ['_id', '_errors', '_old_values'])

      base.extend(ClassMethods)
      base.send :include, Hooks
      base.send :include, Changes

      base.define_hook :validate
      base.define_hook :after_initialize
      base.define_hook :before_save
      base.define_hook :after_save
      base.define_hook :before_destroy
      base.define_hook :after_destroy
    end

    ##
    # Adds instance variables and initializes its
    #
    # @param: hash [hash] initials values for fields
    #
    def initialize(hash={})
      self.class.fields.each do |field|
        self.singleton_class.send(:attr_accessor, field)
      end

      # initialize values of fields
      hash.keys.each do |field|
        if self.respond_to? field
          self.send("#{field}=", hash[field])
        end
      end

      self.run_hook :after_initialize
      set_old_values
    end

    ##
    # Writes model in database
    #
    def save_without_validation
      self.run_hook :before_save
      document =  {}

      # remove '@' from each instance variable name
      # don't save internal fields ('_xxxx')
      self.instance_variables.map{ |x| x.to_s[1..-1] }.each do |field|
        document[field] = self.send(field) unless field[0] == '_'
      end

      if self._id
        result = Driver.client[self.class.coll_name]
          .find({'_id' => self._id}).update_one(document, {:upsert => true})
      else
        document['_id'] = BSON::ObjectId.new
        Driver.client[self.class.coll_name].insert_one(document)
        self._id = document['_id']
      end

      self.run_hook :after_save
      set_old_values

      result ? true : false
    end

    ##
    # Validates and writes model in database
    #
    def save
      result = false

      if self.validate
        result = self.save_without_validation
      end

      result ? true : false
    end

    ##
    # Validates and writes model in database
    # Throws an exception when the document is invalid
    #
    def save!
      result = false

      if self.validate
        result = self.save_without_validation
      else
        raise Exceptions::Validations.new(self._errors)
      end

      result ? true : false
    end

    ##
    # Updates field of document in database (atomic operation)
    #
    def set(field, value)
      result = false

      if self.respond_to?(field) and field[0] != '_'
        self.send("#{field}=", value)

        if self.validate
          result = Driver.client[self.class.coll_name].find({'_id' => self._id})
            .update_one({'$set' => {field => value}})
        end
      end

      result ? true : false
    end

    ##
    # Update document with params
    #
    def update(params)
      params.keys.each do |field|
        if self.respond_to? field and field[0] != '_'
          self.send("#{field}=", params[field])
        end
      end

      self.save
    end

    ##
    # Removes document from database
    #
    def destroy
      self.run_hook :before_destroy
      result = Driver.client[self.class.coll_name].find({'_id' => self._id}).delete_one
      self.run_hook :after_save

      result ? true : false
    end

    ##
    # Reload fields with database values
    #
    def reload
      db_document = self.class.find({_id: self._id}).mongo_cursor.first

      if db_document
        # initialize values of fields
        db_document.keys.each do |field|
          if self.respond_to? field and field != '_id'
            self.send("#{field}=", db_document[field])
          end
        end

        self._errors = {}
        self.run_hook :after_initialize
        set_old_values
        self
      else
        false
      end
    end

    ##
    # Return mongodb id in string format
    #
    def id
      self._id.to_s if self._id
    end

    ##
    # Returns true if model has errors
    #
    def errors?
      (self._errors and not self._errors.empty?) ? true : false
    end

    ##
    # Validates model and returns true if model is valid
    #
    def validate
      self.run_hook :validate
      not self.errors?
    end

    ##
    # Returns hash representation
    # Can receive the name of other method to returns template
    # If model is invalid, returns errors
    #
    # @param: name [string] instance method to be called
    # @param: options [hash] options used in 'name', method
    #
    def template(name=nil, options=nil)
      if self.errors?
        self._errors
      elsif name and self.respond_to? name
        self.send(name, options)
      else
        hash = {'id' => self.id}

        self.instance_variables.each do |name|
          unless name.to_s.include? '@_'
            hash[name.to_s.delete('@')] = self.instance_variable_get(name)
          end
        end

        hash
      end
    end
  end
end
