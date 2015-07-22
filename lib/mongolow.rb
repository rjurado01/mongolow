require 'hooks'
require 'mongo'
require 'mongolow/version'
require 'mongolow/exceptions'
require 'mongolow/driver'
require 'mongolow/cursor'
require 'mongolow/changes'
require 'mongolow/validations'
require 'mongolow/model'

module Mongolow
  if File.exist?(File.join('config', "mongolow.yml"))
    config = YAML.load_file('config/mongolow.yml')[ENV['ENV']]

    if config
      Mongolow::Driver.initialize(config['host'], config['port'], config['database'])
    end
  end
end
