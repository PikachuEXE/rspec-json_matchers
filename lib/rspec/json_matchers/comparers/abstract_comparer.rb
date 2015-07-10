require "abstract_class"
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
        attr_reader *[
          :actual,
          :expected,
          :reasons,
          :value_matching_proc,
        ]

        # Creates a comparer that actually use the {value_matching_proc} for matching {#actual} and {#expected}
        # This class is respossible to aggregating
        # the matching result for each element of {#expected},
        # and compare the keys/indices as well
        #
        # @param actual [Object] the actual value
        # @param expected [Object] the expected value
        # @param reasons [Array<String>]
        #   failure reasons, mostly the path parts
        # @param value_matching_proc [Proc]
        #   the proc that actually compares the expected & actual and returns a boolean
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

          private
          attr_reader *[
            :actual,
            :expected,
            :reasons,
            :value_matching_proc,

            :comparer_class,
          ]
          public

          # Create a "matching" operation object that can return a {Comparers::ComparisonResult}
          #
          # @param expected [Object] the expected "thing", should be an {Enumerable}
          # @param actual [Object] the actual "thing", should be an {Enumerable}
          # @param reasons [Array<String>]
          #   failure reasons, mostly the path parts
          # @param value_matching_proc [Proc]
          #   the proc that actually compares the expected & actual and returns a boolean
          # @param comparer_class [Class<AbstractComparer>]
          #   the class that should be used recursively
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

            private
            attr_reader *[
              :element,

              :actual,
              :expected,
              :reasons,

              :value_matching_proc,

              :comparer_class,
            ]
            public

            # Create a "matching" operation object that can return a {Comparers::ComparisonResult}
            # Unlike {HasMatchedValues}, this is for an element of `expected`
            #
            # @param element [Integer, String, Symbol] a index/key from expected (not value)
            # @param (see HasMatchedValues#initialize)
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

            private

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

        class HasMatchedHashValues < HasMatchedValues
          def each_element_enumerator
            expected.each_key
          end

          def has_matched_value_class
            HasMatchedHashValue
          end

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
      end
    end
  end
end
