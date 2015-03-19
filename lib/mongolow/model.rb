# encoding: utf-8

module Mongolow
  module Model
    module ClassMethods
      ##
      # Returns model fields
      # When new initialize is created new instance variable is added for each field
      #
      def fields
        @fields ? @fields : []
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
        @fields = ['_id', '_errors'] unless @fields

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
        return Mongolow::Cursor.new(self, Driver.session[coll_name].find(query))
      end

      ##
      # Returns the number of documents
      #
      def count
        return Driver.session[coll_name].count
      end

      ##
      # Returns the first document
      #
      def first
        return self.new(Driver.session[coll_name].find_one)
      end

      ##
      # Removes all documents
      #
      def destroy_all
        Driver.session[coll_name].remove
      end
    end

    ##
    # Add class methods
    #
    def self.included(base)
      base.extend(ClassMethods)
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
    end

    ##
    # Validates and writes model in database
    #
    def save
      before_validate

      if validate
        before_save

        document = {}
        # remove '@' from each instance variable name
        self.instance_variables.map{ |x| x.to_s[1..-1] }.each do |field|
          document[field] = self.send(field)
        end

        if self._id
          Driver.session[self.class.coll_name].update(
            {'_id' => self._id}, document, {:upsert => true})
        else
          self._id = Driver.session[self.class.coll_name].insert(document)
        end

        after_save
      end
    end

    ##
    # Updates field of document in database (atomic operation)
    #
    def set(field, value)
      if self.respond_to?(field) and field.to_s != '_id'
        Driver.session[self.class.coll_name].update(
          {'_id' => self._id},
          {'$set' => {field => value}}
        )

        self.send("#{field}=", value)
      end
    end

    ##
    # Removes document from database
    #
    def destroy
      before_destroy

      Driver.session[self.class.coll_name].remove({'_id' => self._id})

      after_destroy
    end

    private

    def validate
      true
    end

    def after_initialize
    end

    def before_validate
    end

    def before_save
    end

    def after_save
    end

    def before_destroy
    end

    def after_destroy
    end
  end
end
