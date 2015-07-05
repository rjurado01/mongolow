require 'mongo'

include Mongo

module Mongolow
  class Driver
    class << self
      def initialize(ip, port, database_name)
        Mongo::Logger.logger = Logger.new('log/mongo_logfile.log')
        @client = Mongo::Client.new("mongodb://#{ip}:#{port}/#{database_name}")
      end

      def client
        @client
      end

      def drop_database
        @client.database.drop
      end

      def close
        # waiting mongo add this to stable version
        # @client.close
      end
    end
  end
end
