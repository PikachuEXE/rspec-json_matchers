require "json"

module RSpec
  module JsonMatchers
    module Matchers
      # @api
      def be_json
        BeJsonMatcher.new
      end

      # @api private
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

        # includes expected, not exactly equal
        # @api
        def with_content(expected)
          BeJsonWithContentMatcher.new(expected)
        end

        # includes expected, not exactly equal
        # @api
        def with_sizes(expected)
          BeJsonWithSizesMatcher.new(expected)
        end

        def description
          "be a valid JSON string"
        end

        def failure_message_for_positive
          "expected value to be parsed as JSON, but failed"
        end
        alias :failure_message :failure_message_for_positive

        def failure_message_for_negative
          "expected value not to be parsed as JSON, but succeeded"
        end
        alias :failure_message_when_negated :failure_message_for_negative

        private

        def has_parser_error?
          !!@has_parser_error
        end
      end
    end
  end
end

# These files are required since the classes are only required on runtime, not load time
require_relative "be_json_with_content_matcher"
require_relative "be_json_with_sizes_matcher"
