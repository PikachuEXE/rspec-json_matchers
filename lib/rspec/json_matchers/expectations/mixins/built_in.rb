require "abstract_class"

require_relative "../core"
require_relative "../abstract"

module RSpec
  module JsonMatchers
    module Expectations
      # @api
      #   The modules under this module can be included (in RSpec)
      module Mixins
        # @api
        #   All classes within module should be able to be used / extended
        #
        # A group of expectation classes provided by this gem
        # Other extension gems (if any) should create another namespace
        # if they intend to provide extra expectation classes
        module BuiltIn
          # Whatever the value is, it just passes
          # A more verbose solution than passing {Object} in
          # (That also works since everything parsed by {JSON} inherits from {Object})
          #
          # @example
          #   { key_with_unstable_content => Anything }
          class Anything < Expectations::Core::SingletonExpectation
            def expect?(*_args)
              true
            end
          end

          # Checks the value is a {Numeric} & less then zero
          #
          # @note (see Expectations::Private::NumericExpectation)
          class PositiveNumber < Expectations::Abstract::NumericExpectation
            EXPECTED_VALUE_CLASS = Numeric

            def expect?(value)
              super && value > 0
            end
          end

          # Checks the value is a {Numeric} & less then zero
          #
          # @note (see Expectations::Private::NumericExpectation)
          class NegativeNumber < Expectations::Abstract::NumericExpectation
            EXPECTED_VALUE_CLASS = Numeric

            def expect?(value)
              super && value < 0
            end
          end

          # Checks the value is a {TrueClass} or {FalseClass}
          #
          # @note
          #   The class does use name Boolean since so many gems uses it already
          #   You can also use gems like https://github.com/janlelis/boolean2/
          class BooleanValue < Expectations::Core::SingletonExpectation
            EXPECTED_VALUE_CLASS = Numeric

            def expect?(value)
              true == value || false == value
            end
          end

          # Takes exactly one object and converts to an expectation object (if not already)
          # Validates `value` to be {Array}
          # And uses stored expectation for checking all elements of `value`
          class ArrayOf < Expectations::Core::SingleValueCallableExpectation
            EXPECTED_VALUE_CLASS = Array

            private
            attr_reader :children_elements_expectation
            public

            def expect?(value)
              value.is_a?(EXPECTED_VALUE_CLASS) &&
                (empty_allowed? || !value.empty?) &&
                value.all? {|v| children_elements_expectation.expect?(v) }
            end

            # {Enumerable#all?} returns `true` when collection is empty
            # So we provide a way to reject an empty collection
            #
            # @return [ArrayOf] the matcher itself
            def allow_empty(allow = true)
              @empty_allowed = !!allow
              self
            end

            # A more verbose alias for `allow_empty(false)`
            #
            # @return (see #allow_empty)
            def disallow_empty
              allow_empty(false)
            end

            private

            def initialize(value)
              @children_elements_expectation = Expectation.build(value)
              @empty_allowed = true
            end

            def empty_allowed?
              !!@empty_allowed
            end
          end

          # (see CompositeExpectation)
          # It passes when any of expectation returns true
          class AnyOf < Expectations::Core::CompositeExpectation
            def expect?(value)
              expectations.any? do |expectation|
                expectation.expect?(value)
              end
            end
          end

          # (see CompositeExpectation)
          # It passes when all of expectations return true
          class AllOf < Expectations::Core::CompositeExpectation
            def expect?(value)
              expectations.all? do |expectation|
                expectation.expect?(value)
              end
            end
          end

          # Takes any number of {Integer} or {Range} (if not already)
          # Validates `value` to be {Array}
          # And the size matches any value passed in
          #
          # @note
          #   For behaviour of "and" (which should be a rare case)
          #   Combine {AllOf} & {ArrayWithSize}
          #   Or raise an issue to add support for switching to "and" with another method call
          class ArrayWithSize < AnyOf
            EXPECTED_VALUE_CLASS = Array

            # `Fixnum` & `Bignum` will be returned instead of `Integer`
            # in `#class` for numbers
            EXPECTED_VALUE_CLASS_TO_EXPECTATION_CLASS_MAPPING = {
              Fixnum  => -> (v) { Expectations::Private::Eq[v] },
              Bignum  => -> (v) { Expectations::Private::Eq[v] },
              Range   => -> (v) { Expectations::Private::InRange[v] },
            }.freeze

            class << self
              # Overrides {Expectation.build}
              def build(value)
                expectation_classes_mappings.fetch(value.class) do
                  -> (_) { raise ArgumentError, <<-ERR }
                    Expected expection(s) to be kind of
                    #{EXPECTED_VALUE_CLASS_TO_EXPECTATION_CLASS_MAPPING.keys.inspect}
                    but found #{value.inspect}
                  ERR
                end.call(value)
              end

              private

              # @return [Hash]
              def expectation_classes_mappings
                EXPECTED_VALUE_CLASS_TO_EXPECTATION_CLASS_MAPPING
              end
            end

            def expect?(value)
              value.is_a?(EXPECTED_VALUE_CLASS) &&
                super(value.size)
            end
          end
        end
      end
    end
  end
end
