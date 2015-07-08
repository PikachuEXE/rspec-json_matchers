require "set"
require_relative "../expectation"
require_relative "comparison_result"

module RSpec
  module JsonMatchers
    module Comparers
      # @api private
      # @abstract
      class AbstractComparer
        attr_reader *[
          :actual,
          :expected,
          :reasons,
          :value_matching_proc,
        ]

        def self.compare(*args)
          new(*args).compare
        end

        def initialize(actual, expected, reasons, value_matching_proc)
          @actual   = actual
          @expected = expected
          @reasons  = reasons

          @value_matching_proc = value_matching_proc
        end

        # @return [Boolean]
        #   `true` if #actual & #expected are the same
        def compare
          if has_matched_value?
            return ComparisonResult.new(true, reasons)
          end

          has_matched_collection?
        end

        private

        def has_matched_value?
          value_matching_proc.call(expected, actual)
        end

        def has_matched_collection?
          return ComparisonResult.new(false, reasons) unless is_collection?
          return ComparisonResult.new(false, reasons) unless has_matched_class?
          return ComparisonResult.new(false, reasons) unless has_matched_keys?

          ComparisonResult.new(has_matched_values?, reasons)
        end

        def is_collection?
          actual.is_a?(Array) || actual.is_a?(Hash)
        end

        def has_matched_class?
          actual.class == expected.class
        end

        # @note with side effect on `#reasons`
        def has_matched_keys?
          raise NotImplementedError
        end

        # @note with side effect on `#reasons`
        def has_matched_values?
          if expected.is_a?(Array)
            expected.each_index.all? do |index|
              next false unless index < actual.size

              result = self.class.compare(actual[index], expected[index], reasons, value_matching_proc)
              result.matched?.tap do |matched|
                @reasons = result.reasons.unshift("[#{index}]") unless matched
              end
            end
          else
            expected.each_key.all? do |key|
              next false unless actual.key?(key.to_s)

              result = self.class.compare(actual[key.to_s], expected[key], reasons, value_matching_proc)
              result.matched?.tap do |matched|
                @reasons = result.reasons.unshift(key.to_s) unless matched
              end
            end
          end
        end
      end
    end
  end
end
