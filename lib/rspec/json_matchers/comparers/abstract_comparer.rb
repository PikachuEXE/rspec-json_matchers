require "abstract_class"
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
          comparison_result = {
            Array => HasMatchedArrayValues,
            Hash  => HasMatchedHashValues,
          }.fetch(expected.class).
            new(expected, actual, reasons, value_matching_proc, self.class).
            comparison_result

          comparison_result.matched?.tap do |matched|
            @reasons = comparison_result.reasons unless matched
          end
        end

        class HasMatchedValues
          extend AbstractClass

          attr_reader *[
            :actual,
            :expected,
            :reasons,
            :value_matching_proc,

            :comparer_class,
          ]

          def initialize(expected, actual, reasons, value_matching_proc, comparer_class)
            @actual   = actual
            @expected = expected
            @reasons  = reasons

            @value_matching_proc  = value_matching_proc

            @comparer_class       = comparer_class
          end

          def comparison_result
            each_element_enumerator.each do |element|
              comparison_result = has_matched_value_class.new(
                element,
                expected,
                actual,
                reasons,
                value_matching_proc,
                comparer_class,
              ).comparison_result

              return comparison_result unless comparison_result.matched?
            end

            Comparers::ComparisonResult.new(true, reasons)
          end

          def each_element_enumerator
            raise NotImplementedError
          end

          def has_matched_value_class
            raise NotImplementedError
          end

          class HasMatchedValue
            extend AbstractClass

            attr_reader *[
              :element,

              :actual,
              :expected,
              :reasons,

              :value_matching_proc,

              :comparer_class,
            ]

            def initialize(element, expected, actual, reasons, value_matching_proc, comparer_class)
              @element  = element
              @actual   = actual
              @expected = expected
              @reasons  = reasons

              @value_matching_proc  = value_matching_proc

              @comparer_class       = comparer_class
            end

            def comparison_result
              return false unless actual_contain_element?

              result.tap do |result|
                next if result.matched?
                result.reasons.push(reason)
              end
            end

            def result
              @result ||= comparer_class.
                compare(
                  actual_for_element,
                  expected_for_element,
                  reasons,
                  value_matching_proc,
                )
            end

            def actual_contain_element?
              raise NotImplementedError
            end

            def actual_for_element
              raise NotImplementedError
            end
            def expected_for_element
              raise NotImplementedError
            end

            def reason
              raise NotImplementedError
            end
          end
        end

        class HasMatchedArrayValues < HasMatchedValues
          def each_element_enumerator
            expected.each_index
          end

          def has_matched_value_class
            HasMatchedArrayValue
          end

          class HasMatchedArrayValue < HasMatchedValues::HasMatchedValue
            alias_method :index, :element

            def actual_contain_element?
              index < actual.size
            end

            def actual_for_element
              actual[index]
            end
            def expected_for_element
              expected[index]
            end

            def reason
              "[#{index}]"
            end
          end
        end

        class HasMatchedHashValues < HasMatchedValues
          def each_element_enumerator
            expected.each_key
          end

          def has_matched_value_class
            HasMatchedHashValue
          end

          class HasMatchedHashValue < HasMatchedValues::HasMatchedValue
            alias_method :key, :element

            def actual_contain_element?
              actual.key?(key.to_s)
            end

            def actual_for_element
              actual[key.to_s]
            end
            def expected_for_element
              expected[key]
            end

            def reason
              key
            end
          end
        end
      end
    end
  end
end
