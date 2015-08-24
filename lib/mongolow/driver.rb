require 'mongo'

include Mongo

module Mongolow
  class Driver
    class << self
      def initialize(ip, port, database_name)
        if File.directory?('log')
          Mongo::Logger.logger = Logger.new('log/mongo_logfile.log')
        end

        Mongo::Logger.logger.level = ::Logger::INFO
        @client = Mongo::Client.new("mongodb://#{ip}:#{port}/#{database_name}")
      end

      def initialize_from_file(path)
        if File.exist?(path)
          config = YAML.load_file(path)[ENV['ENV']]

          if config
            self.initialize(config['host'], config['port'], config['database'])
          end
        end
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
