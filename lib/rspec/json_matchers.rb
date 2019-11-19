require 'rspec'

require_relative 'json_matchers/version'
require_relative 'json_matchers/matchers'
require_relative 'json_matchers/expectation'
require_relative 'json_matchers/expectations'

# The namespace for {RSpec}
# We only add {JsonMatchers} to it
module RSpec
  # The actual namespace for this gem
  # All other classes/modules are defined within this module
  module JsonMatchers; end
end
