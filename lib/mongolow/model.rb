module Mongolow
  module Model
    module ClassMethods
      ##
      # Returns model fields
      # When new instance is created new instance variable is added for each field
      #
      def fields
        @fields || []
      end

      ##
      # Returns public fields
      # Internal fields begin with '_'
      #
      def public_fields
        fields.reject { |field_name| field_name[0] == '_' }
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
        @fields.push name.to_s unless @fields.include? name
      end

      ##
      # Returns collection name for model used in Mongodb
      #
      def coll_name
        name.split('::').last.split(/(?=[A-Z])/).map(&:downcase).join('_')
      end

      ##
      # Selects documents and returns a cursor to the selected documents
      #
      # @param: query [hash]
      #
      def find(filter={}, options={})
        Mongolow::Cursor.new(self, filter, options)
      end

      ##
      # Find model by id
      #
      # @param: id [string/BSON::ObjectId]
      #
      def find_by_id(id)
        unless id.class == BSON::ObjectId
          id = BSON::ObjectId.legal?(id) ? BSON::ObjectId.from_string(id) : nil
        end

        Driver.client[self.class.coll_name].find('_id' => id).first
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
        document = Driver.client[coll_name].find(query).first
        new(document) if document
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
        if (model = find_by_id(id))
          model.run_hook :before_destroy
          model.destroy
          model.run_hook :after_destroy
          true
        else
          false
        end
      end

      ##
      # Initialize and save new model
      #
      def create(hash={})
        model = new(hash)
        model.save
        model
      end
    end

    ##
    # Adds class methods and hooks
    #
    def self.included(base)
      base.instance_variable_set(:@fields, %w[_id _errors _old_values])

      base.extend(ClassMethods)
      base.send :include, Hooks
      base.send :include, Changes
      base.send :include, Validations

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
        singleton_class.send(:attr_accessor, field)
      end

      # initialize values of fields
      assign_attributes(hash)

      # initialize internal variables
      self._errors = {}
      self._old_values = {}

      run_hook :after_initialize
    end

    ##
    # Set attributes values from hash
    #
    def assign_attributes(hash={})
      hash.keys.each do |field|
        instance_variable_set("@#{field}", hash[field]) if respond_to? field
      end
    end

    ##
    # Writes model in database
    #
    def save_without_validation
      run_hook :before_save
      document = {}

      self.class.public_fields.each do |field|
        document[field] = public_send(field)
      end

      if _id
        result = find_by_id(_id).update_one(document, upsert: true)
      else
        document['_id'] = BSON::ObjectId.new
        Driver.client[self.class.coll_name].insert_one(document)
        self._id = document['_id']
      end

      run_hook :after_save
      set_old_values

      result ? true : false
    end

    ##
    # Validates and writes model in database
    #
    def save
      validate ? save_without_validation : false
    end

    ##
    # Validates and writes model in database
    # Throws an exception when the document is invalid
    #
    def save!
      raise Exceptions::Validations.new(_errors) unless validate

      validate ? save_without_validation : false
    end

    ##
    # Updates field of document in database (atomic operation)
    #
    def set(field, value)
      return false unless field && self.class.public_fields.include?(field.to_s)

      send("#{field}=", value)

      result = Driver.client[self.class.coll_name].find('_id' => _id)
                     .update_one('$set' => {field => value})

      result ? true : false
    end

    ##
    # Update document with params
    #
    def update(params)
      params.keys.each do |field|
        instance_variable_set("@#{field}", params[field]) if respond_to?(field) && field[0] != '_'
      end

      save
    end

    ##
    # Removes document from database
    #
    def destroy
      run_hook :before_destroy
      result = Driver.client[self.class.coll_name].find('_id' => _id).delete_one
      run_hook :after_destroy

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
      self._errors = {}
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
