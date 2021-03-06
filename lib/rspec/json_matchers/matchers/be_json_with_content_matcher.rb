# frozen_string_literal: true

require "json"
require "awesome_print"

require_relative "be_json_matcher"
require_relative "../utils"

module RSpec
  module JsonMatchers
    module Matchers
      # @api private
      # @abstract
      #
      # Parent of matcher classes that requires {#at_path} & {#with_exact_keys}
      # This is not merged with {BeJsonMatcher}
      # since it should be able to be used alone
      class BeJsonWithContentMatcher < BeJsonMatcher
        attr_reader(
          :path,
        )

        def initialize(expected)
          @expected     = expected
          @path         = JsonMatchers::Utils::KeyPath::Path.new("")
        end

        def matches?(*_args)
          super && has_valid_path? && expected_and_actual_matched?
        end

        def does_not_match?(*args)
          !matches?(*args) && has_valid_path?
        end

        # Override {BeJsonMatcher#actual}
        # It return actual object extracted by {#path}
        # And also detect & set state for path error
        # (either it's invalid or fails to extract)
        #
        # @return [Object]
        #   extracted object but could be object in the middle
        #   when extraction failed
        def actual
          result = path.extract(super)
          has_path_error! if result.failed?
          result.object
        end

        # Sets the path to be used for object,
        # to avoid passing a deep nested
        # {Hash} or {Array} as expectation
        # Defaults to "" (if this is not called)
        #
        # The path uses period (".") as separator for parts
        # Also period cannot be used as path name as a side-effect
        #
        # This does NOT raise error if the path is invalid
        # (like having 2 periods, 1 period at the start/end of string)
        # But it will fail the example with both `should` & `should_not`
        #
        # @param path [String] the "path" to be used
        #
        # @return [BeJsonWithSomethingMatcher] the match itself
        #
        # @throw [TypeError] when input is not a string
        def at_path(path)
          @path = JsonMatchers::Utils::KeyPath::Path.new(path)
          self
        end

        # Overrides {BeJsonMatcher#failure_message}
        def failure_message
          return super if has_parser_error?

          failure_message_for(true)
        end

        # Overrides {BeJsonMatcher#failure_message_when_negated}
        def failure_message_when_negated
          return super if has_parser_error?

          failure_message_for(false)
        end

        private

        attr_reader(
          :expected,
        )

        def failure_message_for(should_match)
          return invalid_path_message unless has_valid_path?
          return path_error_message if has_path_error?

          inspection_messages(should_match)
        end

        # @return [Bool] Whether `expected` & `parsed` are "equal"
        def expected_and_actual_matched?
          extracted_actual = actual
          return false if has_path_error?

          expectation = Expectation.build(expected)
          expectation.expect?(extracted_actual)
        end

        def reasons
          @reasons ||= []
        end

        def inspection_messages(should_match)
          [
            ["expected", inspection_messages_prefix(should_match), "to match:"].
              compact.map(&:strip).join(" "),
            expected.awesome_inspect(indent: -2),
            "",
            "actual:",
            actual.awesome_inspect(indent: -2),
            "",
            inspection_message_for_reason,
          ].join("\n")
        end

        def inspection_messages_prefix(should_match)
          should_match ? nil : "not"
        end

        def inspection_message_for_reason
          reasons.any? ? "reason/path: #{reasons.reverse.join('.')}" : nil
        end

        def original_actual
          @actual
        end

        def has_path_error?
          @has_path_error
        end

        def has_path_error!
          @has_path_error = true
        end

        # For both positive and negative
        def path_error_message
          [
            %(path "#{path}" does not exists in actual: ),
            original_actual.awesome_inspect(indent: -2),
          ].join("\n")
        end

        def has_valid_path?
          (path.nil? || path.valid?)
        end

        # For both positive and negative
        def invalid_path_message
          %(path "#{path}" is invalid)
        end
      end
    end
  end
end
