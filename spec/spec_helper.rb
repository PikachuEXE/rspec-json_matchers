$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "rspec-json_matchers"

if ENV["TRAVIS"]
  require "coveralls"
  Coveralls.wear!
end

RSpec.configure do |config|
  config.include RSpec::JsonMatchers::Matchers
end
