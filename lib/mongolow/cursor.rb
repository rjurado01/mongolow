module Mongolow
  class Cursor
    include Enumerable

    attr_accessor :mongo_cursor

    def initialize(obj_class, mongo_cursor)
      @obj_class = obj_class
      @mongo_cursor = mongo_cursor
    end

    def first
      if doc = @mongo_cursor.first
        @obj_class.new(doc)
      end
    end
    
    def all
      @mongo_cursor.map do |doc|
        @obj_class.new(doc)
      end
    end

    def count
      @mongo_cursor.count
    end

    def limit(n)
      @mongo_cursor = @mongo_cursor.limit(n)
      return self
    end

    def skip(n)
      @mongo_cursor = @mongo_cursor.skip(n)
      return self
    end

    def find(selector)
      @mongo_cursor.selector.merge!(selector)
      return self
    end
  end
end
