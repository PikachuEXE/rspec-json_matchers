
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rspec/json_matchers/version"

Gem::Specification.new do |spec|
  spec.name          = "rspec-json_matchers"
  spec.version       = RSpec::JsonMatchers::VERSION
  spec.authors       = ["PikachuEXE"]
  spec.email         = ["pikachuexe@gmail.com"]

  spec.summary       = "A collection of RSpec matchers for testing JSON data."
  spec.description   = <<-DESC
    This gem provides a collection of RSpec matchers for testing JSON data.
    It aims to make JSON testing flexible & easier,
    especially for testing multiple properties.
    It does not and will not have anything related to JSON Schema.
  DESC
  spec.homepage      = "https://github.com/PikachuEXE/rspec-json_matchers"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").
    reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rspec", "~> 3.0"
  spec.add_dependency "awesome_print", "~> 1.6"
  spec.add_dependency "abstract_class", "~> 1.0", ">= 1.0.1"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", ">= 10.0", "<= 13.0"

  spec.add_development_dependency "appraisal", "~> 2.0"

  spec.add_development_dependency "rspec-its", "~> 1.0"

  spec.add_development_dependency "gem-release", "~> 2.0"

  spec.add_development_dependency "inch", "~> 0.6"

  spec.required_ruby_version = ">= 2.3.0"

  spec.required_rubygems_version = ">= 1.4.0"
end
