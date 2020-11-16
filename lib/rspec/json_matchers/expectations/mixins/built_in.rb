# frozen_string_literal: true

require "set"
require "abstract_class"

require_relative "../core"
require_relative "../abstract"

module RSpec
  module JsonMatchers
    module Expectations
      # @api
      #   The modules under this module can be included (in RSpec)
      #
      # If this gem or extensions gems decide to
      # add different groups of expectations classes
      # Which aim to be included in example groups
      # They should add the namespace modules here
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
          # (That also works since everything parsed
          # by {JSON} inherits from {Object})
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
            def expect?(value)
              super && value > 0
            end
          end

          # Checks the value is a {Numeric} & less then zero
          #
          # @note (see Expectations::Private::NumericExpectation)
          class NegativeNumber < Expectations::Abstract::NumericExpectation
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
            def expect?(value)
              true == value || false == value
            end
          end

          # Takes exactly one object and converts to
          # an expectation object (if not already)
          # Validates `value` to be {Array}
          # And uses stored expectation for checking all elements of `value`
          class ArrayOf < Expectations::Core::SingleValueCallableExpectation
            def expect?(value)
              value.is_a?(Array) &&
                (empty_allowed? || !value.empty?) &&
                value.all? { |v| children_elements_expectation.expect?(v) }
            end

            # {Enumerable#all?} returns `true` when collection is empty
            # So this method can be called to signal the expectation to
            # do or do not expect an empty collection
            #
            # @param allow [Boolean]
            #   optional
            #   Should empty collection be "expected"
            #
            # @return [ArrayOf] the matcher itself
            def allow_empty(allow = true)
              @empty_allowed = allow
              self
            end

            # A more verbose alias for `allow_empty(false)`
            #
            # @return (see #allow_empty)
            def disallow_empty
              allow_empty(false)
            end

            private

            attr_reader :children_elements_expectation

            def initialize(value)
              @children_elements_expectation = Expectation.build(value)
              @empty_allowed = true
            end

            def empty_allowed?
              @empty_allowed
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

          # (see AnyOf)
          # It will pass regardless of {#expectations}
          # if the value is `nil`
          class NullableOf < AnyOf
            def expect?(value)
              value.nil? || super
            end
          end

          # Takes any number of {Integer} or {Range} (if not already)
          # Validates `value` to be {Array}
          # And the size matches any value passed in
          #
          # @note
          #   For behaviour of "and" (which should be a rare case)
          #   Combine {AllOf} & {ArrayWithSize}
          #   Or raise an issue to add support for
          #   switching to "and" with another method call
          class ArrayWithSize < AnyOf
            # `Fixnum` & `Bignum` will be returned instead of `Integer`
            # in `#class` for numbers
            # But since 2.4.x it will be `Integer`
            EXPECTED_VALUE_CLASS_TO_EXPECTATION_CLASS_MAPPING = begin
              {
                Range   => ->(v) { Expectations::Private::InRange[v] },
                Integer => ->(v) { Expectations::Private::Eq[v] },
              }.tap do |result_hash|
                # This fix is similar to
                # https://github.com/rails/rails/pull/26732
                next if 1.class == Integer

                result_hash.merge!(
                  Integer => ->(v) { Expectations::Private::Eq[v] },
                  Integer => ->(v) { Expectations::Private::Eq[v] },
                )
              end
            end.freeze
            private_constant :EXPECTED_VALUE_CLASS_TO_EXPECTATION_CLASS_MAPPING

            class << self
              # Overrides {Expectation.build}
              def build(value)
                expectation_classes_mappings.fetch(value.class) do
                  ->(_) { fail ArgumentError, <<-ERR }
                    Expected expection(s) to be kind of
                    #{expectation_classes_mappings.keys.inspect}
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
              value.is_a?(Array) &&
                super(value.size)
            end
          end

          # Takes a {Hash}
          # Validates `value` to be {Hash} and
          # contain expected keys & values
          # Extra keys in `value` will not be treated as "unexpected"
          # Unless {#with_exact_keys} is used
          class HashWithContent < Expectations::Core::SingleValueCallableExpectation
            EXPECTED_CLASS = ::Hash
            private_constant :EXPECTED_CLASS

            def expect?(value)
              matches_expected_class?(value) &&
                matches_content_expectations?(value) &&
                matches_keys_exactly?(value)
            end

            # After calling this method
            # Any extra key in `value` will be marked as "unexpected"
            #
            # By default the expectation won't care about extra keys in `value`
            def with_exact_keys
              @require_exact_key_matches = true
              self
            end

            private

            attr_reader :require_exact_key_matches
            alias_method(
              :require_exact_key_matches?,
              :require_exact_key_matches,
            )
            attr_reader :expected_value

            def matches_expected_class?(value)
              value.is_a?(::Hash)
            end

            def matches_keys_exactly?(actual_value)
              return true unless require_exact_key_matches?

              ::Set.new(expected_value.keys.map(&:to_s)) ==
                ::Set.new(actual_value.keys.map(&:to_s))
            end

            def matches_content_expectations?(actual_value)
              expected_value.each_pair.all? do |exp_key, exp_value|
                unless actual_value.key?(exp_key) ||
                    actual_value.key?(exp_key.to_s)
                  return false
                end

                value_from_actual = actual_value.fetch(exp_key) do
                  actual_value.fetch(exp_key.to_s)
                end
                Expectation.build(exp_value).expect?(value_from_actual)
              end
            end

            def initialize(value)
              unless value.is_a?(::Hash)
                fail ArgumentError, "a #{EXPECTED_CLASS} is required"
              end

              @expected_value = value
            end
          end
        end
      end
    end
  end
end
