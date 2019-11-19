# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'rspec-json_matchers'

if ENV['TRAVIS']
  require 'simplecov'
  SimpleCov.start

  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

RSpec.configure { |config| config.include RSpec::JsonMatchers::Matchers }
