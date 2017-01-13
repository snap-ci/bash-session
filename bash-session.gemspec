# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bash/session/version'

Gem::Specification.new do |spec|
  spec.name          = "bash-session"
  spec.version       = Bash::Session::VERSION
  spec.authors       = ["Snap CI"]
  spec.email         = ["support@snap-ci.com"]
  spec.summary       = %q{A minimalistic gem for a persistent bash session.}
  spec.description   = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.2'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_development_dependency "minitest"
end
