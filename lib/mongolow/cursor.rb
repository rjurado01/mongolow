module Mongolow
  class Cursor
    include Enumerable

    attr_reader :obj_class, :filter, :options

    def initialize(obj_class, filter=nil, options={})
      @obj_class = obj_class
      @filter = symbolize_keys(filter)
      @options = symbolize_keys(options)
    end

    def first
      return unless (doc = view.first)

      instance = @obj_class.new(doc)
      instance.send(:set_old_values)
      instance
    end

    def all
      view.map do |doc|
        instance = @obj_class.new(doc)
        instance.send(:set_old_values)
        instance
      end
    end

    def destroy_all
      all.each(&:destroy)
    end

    def limit(size)
      @options[:limit] = size
      self
    end

    def skip(size)
      @options[:skip] = size
      self
    end

    def find(filter=nil, options={})
      @filter.merge! symbolize_keys(filter)
      @options.merge! symbolize_keys(options)
      self
    end

    def sort(params)
      @options[:sort] = symbolize_keys(params)
      self
    end

    private

    def view
      Driver.client[@obj_class.coll_name].find(@filter, @options)
    end

    def method_missing(method, *args, &block)
      super unless view.respond_to?(method)

      view.public_send(method, *args, &block)
    end

    def respond_to_missing?
      true
    end

    def symbolize_keys(hash)
      return {} unless hash

      hash.keys.each do |key|
        hash[(key.to_sym rescue key) || key] = hash.delete(key)
      end

      hash
    end
  end
end
