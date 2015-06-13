require 'mongo'

include Mongo

module Mongolow
  class Driver
    class << self
      def initialize(ip, port, database_name)
        Mongo::Logger.logger = Logger.new('mongo_logfile.log')
        @client = Mongo::Client.new("mongodb://#{ip}:#{port}/#{database_name}")
      end

      def client
        @client
      end

      def drop_database
        @client.database.drop
      end
    end
  end
end
