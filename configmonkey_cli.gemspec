# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'configmonkey_cli/version'

Gem::Specification.new do |spec|
  spec.name          = "configmonkey_cli"
  spec.version       = ConfigmonkeyCli::VERSION
  spec.authors       = ["Sven Pachnit"]
  spec.email         = ["sven@bmonkeys.net"]
  spec.summary       = %q{Configmonkey CLI - dead simple helper for git based server configs}
  spec.description   = %q{Basically chef/puppet for the brainless}
  spec.homepage      = "https://github.com/2called-chaos/configmonkey_cli"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "httparty"
  spec.add_dependency "thor"
  spec.add_dependency "tty-prompt"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
