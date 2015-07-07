require "json"
require "awesome_print"

require_relative "be_json_with_something_matcher"
require_relative "../comparers"
require_relative "../utils"

module RSpec
  module JsonMatchers
    module Matchers
      # @api private
      class BeJsonWithContentMatcher < BeJsonWithSomethingMatcher
        private

        def value_matching_proc
          -> (expected, actual) { Expectation.build(expected).expect?(actual) }
        end
      end
    end
  end
end
