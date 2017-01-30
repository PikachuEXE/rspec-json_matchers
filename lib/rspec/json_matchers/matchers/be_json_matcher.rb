require "json"

module RSpec
  module JsonMatchers
    # Mixin Module to be included into RSpec
    # Other files will define the same module and add methods to this module
    module Matchers
      # @api
      #
      # Used for verifying actual is a valid JSON string
      #
      # @return [BeJsonMatcher]
      def be_json
        BeJsonMatcher.new
      end

      # @api private
      #
      # The implementation for {Matchers#be_json}
      class BeJsonMatcher
        attr_reader :actual

        def matches?(json)
          @actual = JSON.parse(json)
          true
        rescue JSON::ParserError
          @has_parser_error = true
          false
        end

        def does_not_match?(*args)
          !matches?(*args)
        end

        # @api
        #
        # Get a matcher that try to match the content of actual
        # with nested various expectations
        #
        # @param expected [Hash, Array, Object]
        #   the expectation object
        #
        # @return [BeJsonWithContentMatcher] a matcher object
        def with_content(expected)
          BeJsonWithContentMatcher.new(expected)
        end

        # Expectation description in spec result summary
        #
        # @return [String]
        def description
          "be a valid JSON string"
        end

        # Failure message displayed when a positive example failed
        # (e.g. using `should`)
        #
        # @return [String]
        def failure_message
          "expected value to be parsed as JSON, but failed"
        end

        # Failure message displayed when a negative example failed
        # (e.g. using `should_not`)
        #
        # @return [String]
        def failure_message_when_negated
          "expected value not to be parsed as JSON, but succeeded"
        end

        private

        def has_parser_error?
          @has_parser_error
        end
      end
    end
  end
end

# These files are required here
# since the classes are only required
# on runtime but not load time
require_relative "be_json_with_content_matcher"
