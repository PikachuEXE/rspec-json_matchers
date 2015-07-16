require "abstract_class"
require "forwardable"
require "set"
require_relative "../expectation"
require_relative "comparison_result"

module RSpec
  module JsonMatchers
    module Comparers
      # @api private
      # @abstract
      #
      # The parent of all comparer classes
      # It holds most of the responsibility
      # The subclasses only need to implement the behaviour of matching keys
      # when both expected & actual are same type of collection
      class AbstractComparer
        attr_reader(*[
          :actual,
          :expected,
          :reasons,
          :value_matching_proc,
        ])

        # Creates a comparer that actually use the {value_matching_proc}
        # for matching {#actual} and {#expected}
        # This class is respossible to aggregating
        # the matching result for each element of {#expected},
        # and compare the keys/indices as well
        #
        # @param actual [Object]
        #   the actual "thing", should be an {Enumerable}
        # @param expected [Object]
        #   the expected "thing", should be an {Enumerable}
        # @param reasons [Array<String>]
        #   failure reasons, mostly the path parts
        # @param value_matching_proc [Proc]
        #   the proc that actually compares
        #   the expected & actual and returns a boolean
        def initialize(actual, expected, reasons, value_matching_proc)
          @actual   = actual
          @expected = expected
          @reasons  = reasons

          @value_matching_proc = value_matching_proc
        end

        # @return [Boolean]
        #   `true` if #actual & #expected are the same
        def compare
          return ComparisonResult.new(true, reasons) if has_matched_value?

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
          fail NotImplementedError
        end

        # @note with side effect on `#reasons`
        def has_matched_values?
          comparison_result = EXPECTED_VALUE_CLASS_TO_EXPECTATION_MAPPING.
            fetch(expected.class).
            new(self).
            comparison_result

          comparison_result.matched?.tap do |matched|
            @reasons = comparison_result.reasons unless matched
          end
        end

        def actual_keys
          @actual_keys ||= Utils::CollectionKeysExtractor.extract(actual)
        end

        def expected_keys
          @expected_keys ||= Utils::CollectionKeysExtractor.extract(expected)
        end

        # Represents an "expectation" for matching all elements
        # in {#actual} & {#expected}
        class HasMatchedValues
          extend AbstractClass
          extend Forwardable

          public

          # Create a "matching" operation object
          # that can return a {Comparers::ComparisonResult}
          #
          # @param comparer [AbstractComparer]
          #   the comparer that creates this object, for fetching values
          def initialize(comparer)
            @comparer = comparer
          end

          def comparison_result
            each_element_enumerator.each do |element|
              result = comparison_result_for_element(element)

              return result unless result.matched?
            end

            Comparers::ComparisonResult.new(true, reasons)
          end

          def each_element_enumerator
            fail NotImplementedError
          end

          def has_matched_value_class
            fail NotImplementedError
          end

          private

          def_delegators(*[
            :comparer,
            :expected,
            :reasons,
          ])

          attr_reader(*[
            :comparer,
          ])

          def comparer_class
            comparer.class
          end

          def comparison_result_for_element(element)
            has_matched_value_class.
              new(
                element,
                comparer,
              ).comparison_result
          end

          # Represents an "expectation" for matching one element
          # in {#actual} & {#expected}
          class HasMatchedValue
            extend AbstractClass
            extend Forwardable

            public

            # Create a "matching" operation object
            # that can return a {Comparers::ComparisonResult}
            # Unlike {HasMatchedValues}, this is for an element of `expected`
            #
            # @param element [Integer, String, Symbol]
            #   a index/key from expected (not value)
            # @param (see HasMatchedValues#initialize)
            def initialize(element, comparer)
              @element  = element
              @comparer = comparer
            end

            def comparison_result
              return false unless actual_contain_element?

              result.tap do |result|
                next if result.matched?
                result.reasons.push(reason)
              end
            end

            private

            attr_reader(*[
              :element,
              :comparer,
            ])

            def_delegators(*[
              :comparer,
              :expected,
              :actual,
              :reasons,
              :value_matching_proc,
            ])

            def comparer_class
              comparer.class
            end

            def result
              @result ||= comparer_class.
                new(
                  actual_for_element,
                  expected_for_element,
                  reasons,
                  value_matching_proc,
                ).
                compare
            end

            def actual_contain_element?
              fail NotImplementedError
            end

            def actual_for_element
              fail NotImplementedError
            end

            def expected_for_element
              fail NotImplementedError
            end

            def reason
              fail NotImplementedError
            end
          end
        end

        # (see HasMatchedValues)
        # {#expected} should be {Array}
        class HasMatchedArrayValues < HasMatchedValues
          def each_element_enumerator
            expected.each_index
          end

          def has_matched_value_class
            HasMatchedArrayValue
          end

          # (see HasMatchedValues::HasMatchedValue)
          # {#expected} should be {Array}
          class HasMatchedArrayValue < HasMatchedValues::HasMatchedValue
            private

            alias_method :index, :element

            public

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

        # (see HasMatchedValues)
        # {#expected} should be {Hash}
        class HasMatchedHashValues < HasMatchedValues
          def each_element_enumerator
            expected.each_key
          end

          def has_matched_value_class
            HasMatchedHashValue
          end

          # (see HasMatchedValues::HasMatchedValue)
          # {#expected} should be {Array}
          class HasMatchedHashValue < HasMatchedValues::HasMatchedValue
            private

            alias_method :key, :element

            public

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

        EXPECTED_VALUE_CLASS_TO_EXPECTATION_MAPPING = {
          Array => HasMatchedArrayValues,
          Hash  => HasMatchedHashValues,
        }.freeze
        private_constant :EXPECTED_VALUE_CLASS_TO_EXPECTATION_MAPPING
      end
    end
  end
end
