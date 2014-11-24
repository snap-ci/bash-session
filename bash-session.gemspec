# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bash/session/version'

Gem::Specification.new do |spec|
  spec.name          = "bash-session"
  spec.version       = Bash::Session::VERSION
  spec.authors       = ["Akshay Karle"]
  spec.email         = ["akshay.a.karle@gmail.com"]
  spec.summary       = %q{A minimalistic gem for a persistent bash session.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_development_dependency "rspec"
end
