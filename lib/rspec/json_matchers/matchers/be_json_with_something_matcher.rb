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
      class BeJsonWithSomethingMatcher < BeJsonMatcher
        extend AbstractClass

        PATH_PART_SPLITTER = ".".freeze

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

        # Override
        def actual
          result = path.extract(super)
          has_path_error! if result.failed?
          result.object
        end

        # This does NOT raise error to make result looks good
        def at_path(path)
          @path = JsonMatchers::Utils::KeyPath::Path.new(path)
          self
        end

        def with_exact_keys(exactly = true)
          @with_exact_keys = exactly
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
          result = comparer_klass.compare(extracted_actual, expected, reasons, value_matching_proc)

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
