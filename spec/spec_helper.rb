# frozen_string_literal: true

if ENV["COVERALLS"]
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::LcovFormatter]
  )

  SimpleCov.start do
    add_filter "spec/"
  end
end

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require "rspec-json_matchers"

RSpec.configure do |config|
  config.include RSpec::JsonMatchers::Matchers
end
