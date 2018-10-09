# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongolow/version'

Gem::Specification.new do |gem|
  gem.license = "MIT"
  gem.name = "mongolow"
  gem.version = Mongolow::VERSION
  gem.authors = ["Rafael Jurado"]
  gem.email = ["rjurado@openmailbox.org"]
  gem.description = %q{Simple Ruby Object Mapper for Mongo.}
  gem.summary = %q{Simple Ruby Object Mapper for Mongo.}
  gem.homepage = "https://github.com/rjurado01/mongolow"
  gem.files = `git ls-files`.split($/)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "mongo", "~> 2.6.2"
  gem.add_dependency "hooks", "~> 0.4.1"
  gem.add_development_dependency "rspec"
end
