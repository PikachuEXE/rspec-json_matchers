require "json"
require "awesome_print"
require "abstract_class"

require_relative "be_json_matcher"
require_relative "../utils"

module RSpec
  module JsonMatchers
    module Matchers
      # @api private
      # @abstract
      #
      # Parent of matcher classes that requires {#at_path} & {#with_exact_keys}
      # This is not merged with {BeJsonMatcher} since it should be able to be used alone
      class BeJsonWithSomethingMatcher < BeJsonMatcher
        extend AbstractClass

        attr_reader *[
          :expected,
          :path,
          :with_exact_keys,
        ]
        alias_method :with_exact_keys?, :with_exact_keys

        def initialize(expected)
          @expected     = expected
          @path         = JsonMatchers::Utils::KeyPath::Path.new("")
          @exact_match  = false
        end

        def matches?(*_args)
          super && has_valid_path? && expected_and_actual_matched?
        end

        def does_not_match?(*args)
          !matches?(*args) && has_valid_path?
        end

        def description
          super
        end

        # Override {BeJsonMatcher#actual}
        # It return actual object extracted by {#path}
        # And also detect & set state for path error (either it's invalid or fails to extract)
        #
        # @return [Object] extracted object but could be object in the middle when extraction failed
        def actual
          result = path.extract(super)
          has_path_error! if result.failed?
          result.object
        end

        # Sets the path to be used for object, to avoid passing a deep nested {Hash} or {Array} as expectation
        # Defaults to "" (if this is not called)
        # The path uses period (".") as separator for parts
        # (also period cannot be used as path name as a side-effect, but who does?)
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

        # When `exactly` is `true`,
        # makes the matcher to fail the example
        # when actual has more elements than expected even expectation passes
        #
        # When `exactly` is `true`,
        # makes the matcher to pass the example
        # when actual has more elements than expected and expectation passes
        #
        # @param exactly [Boolean] whether the matcher should match keys in actual & expected exactly
        #
        # @return (see #at_path)
        def with_exact_keys(exactly = true)
          @with_exact_keys = !!exactly
          self
        end

        def failure_message_for_positive
          return super if has_parser_error?
          return invalid_path_message unless has_valid_path?
          return path_error_message if has_path_error?

          inspection_messages(true)
        end
        alias :failure_message :failure_message_for_positive

        def failure_message_for_negative
          return super if has_parser_error?
          return invalid_path_message unless has_valid_path?
          return path_error_message if has_path_error?

          inspection_messages(false)
        end
        alias :failure_message_when_negated :failure_message_for_negative

        private

        # @return [Bool] Whether `expected` & `parsed` are "equal"
        def expected_and_actual_matched?
          extracted_actual = actual
          return false if has_path_error?
          result = comparer_klass.new(extracted_actual, expected, reasons, value_matching_proc).compare

          result.matched?.tap do |matched|
            @reasons = result.reasons unless matched
          end
        end

        def reasons
          @reasons ||= []
        end

        def inspection_messages(should_match)
          prefix = !!should_match ? nil : "not"

          messages = [
            ["expected", prefix, "to match:"].compact.map(&:strip).join(" "),
            expected.awesome_inspect(indent: -2),
            "",
            "actual:",
            actual.awesome_inspect(indent: -2),
            "",
          ]
          messages.push "reason/path: #{reasons.reverse.join(".")}" unless reasons.empty?
          messages.join("\n")
        end

        def original_actual
          @actual
        end

        def has_path_error?
          !!@has_path_error
        end

        def has_path_error!
          @has_path_error = true
        end

        # For both positive and negative
        def path_error_message
          %Q|path "#{path}" does not exists in actual: |
          [
            original_actual.awesome_inspect(indent: -2),
          ].join("\n")
        end

        def has_valid_path?
          (path.nil? || path.valid?)
        end

        # For both positive and negative
        def invalid_path_message
          %Q|path "#{path}" is invalid|
        end

        def comparer_klass
          with_exact_keys? ? Comparers::ExactKeysComparer : Comparers::IncludeKeysComparer
        end
      end
    end
  end
end
