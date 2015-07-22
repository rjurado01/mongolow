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
  def self.initialize
    Mongolow::Driver.initialize_from_file('config/mongolow.yml')
  end
end
