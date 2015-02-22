require 'mongo'

include Mongo

module Mongolow
  class Driver
    class << self
      def initialize(ip, port, database_name)
        @session = MongoClient.new( ip, port ).db( database_name )
      end

      def session
        @session
      end
    end
  end
end
