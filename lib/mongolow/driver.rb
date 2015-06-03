require 'mongo'

include Mongo

module Mongolow
  class Driver
    class << self
      def initialize(ip, port, database_name)
        @database_name = database_name
        @client = MongoClient.new( ip, port )
        @session = @client.db( database_name )
      end

      def session
        @session
      end

      def drop_database
        @client.drop_database(@database_name)
      end
    end
  end
end
