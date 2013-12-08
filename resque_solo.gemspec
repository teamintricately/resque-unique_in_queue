# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'resque_solo/version'

Gem::Specification.new do |spec|
  spec.name          = "resque_solo"
  spec.version       = ResqueSolo::VERSION
  spec.authors       = ["Tee Parham"]
  spec.email         = %w(tee@neighborland.com)
  spec.description   = %q{Resque plugin to add unique jobs}
  spec.summary       = %q{Resque plugin to add unique jobs}
  spec.homepage      = "https://github.com/teeparham/resque_solo"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|features)/})
  spec.require_paths = %w(lib)

  spec.required_ruby_version = ">= 1.9.3"

  spec.add_dependency "resque", "~> 1.25.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end