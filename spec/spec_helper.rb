Dir["lib/*.rb"].each {|file| require_relative "../#{file}" }

ENV['ENV'] = 'test'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = [:should, :expect]
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
end