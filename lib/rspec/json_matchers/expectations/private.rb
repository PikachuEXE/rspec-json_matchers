require "abstract_class"

require_relative "core"
require_relative "mixins/built_in"

module RSpec
  module JsonMatchers
    module Expectations
      # @api private
      #   All classes within module should NOT be able
      #   to be used directly / extended
      #
      # All classes in this module are internal expectations used
      # when non-expectation object/class is passed in
      # Extension gems should have their own namespace and
      # should NOT add new classes to this namespace
      # Classes here have dependency on {Core} & {Mixins::BuiltIn}
      #
      # TODO: Remove dependency on {Mixins::BuiltIn}
      module Private
        # @api private
        #   User should just pass an object in
        #
        # Takes exactly one object
        # Use stored value & `==` for checking `value`
        class Eq < Core::SingleValueCallableExpectation
          def expect?(value)
            value == expected_value
          end

          private

          attr_reader :expected_value

          def initialize(value)
            @expected_value = value
          end
        end

        # @api private
        #   User should just pass a class in
        #
        # Takes exactly one object
        # Use stored class for checking `value`
        #
        # @note
        #   Might use a whitelist of acceptable classes
        #   and raise error if other things passed in
        #   in the future
        class KindOf < Core::SingleValueCallableExpectation
          EXPECTED_CLASS = Class
          private_constant :EXPECTED_CLASS

          def expect?(value)
            value.is_a?(expected_class)
          end

          private

          attr_reader :expected_class

          def initialize(value)
            unless value.is_a?(EXPECTED_CLASS)
              fail ArgumentError, "a #{EXPECTED_CLASS} is required"
            end

            @expected_class = value
          end
        end

        # @api private
        #   User should just pass a {Range} in
        #
        # Takes exactly one object
        # Use stored proc for checking `value`
        class InRange < Core::SingleValueCallableExpectation
          EXPECTED_CLASS = Range
          private_constant :EXPECTED_CLASS

          def expect?(value)
            range.cover?(value)
          end

          private

          attr_reader :range

          def initialize(value)
            unless value.is_a?(EXPECTED_CLASS)
              fail ArgumentError, "a #{EXPECTED_CLASS} is required"
            end

            @range = value
          end
        end

        # @api private
        #   User should just pass a {Regexp} in
        #
        # Takes exactly one object
        # Use stored regexp for checking `value`
        class MatchingRegexp < Core::SingleValueCallableExpectation
          EXPECTED_CLASS = Regexp
          private_constant :EXPECTED_CLASS

          def expect?(value)
            # regex =~ string seems to be fastest
            # @see https://stackoverflow.com/questions/11887145/fastest-way-to-check-if-a-string-matches-or-not-a-regexp-in-ruby
            value.is_a?(String) && regexp =~ value
          end

          private

          attr_reader :regexp

          def initialize(value)
            unless value.is_a?(EXPECTED_CLASS)
              fail ArgumentError, "a #{EXPECTED_CLASS} is required"
            end

            @regexp = value
          end
        end

        # @api private
        #   User should just pass a callable in
        #
        # Takes exactly one object
        # Use stored proc for checking `value`
        class SatisfyingCallable < Core::SingleValueCallableExpectation
          def expect?(value)
            callable.call(value)
          end

          private

          attr_reader :callable

          def initialize(value)
            unless value.respond_to?(:call)
              fail(
                ArgumentError,
                "an object which respond to `:call` is required",
              )
            end
            @callable = value
          end
        end

        # @api private
        #   Used internally for returning false
        #
        # Always "fail"
        class Nothing < Expectations::Core::SingletonExpectation
          def expect?(*_args)
            false
          end
        end

        # @api private
        #   Used internally by a matcher method
        #
        # Comparing to {Expectations::Mixins::BuiltIn::ArrayWithSize}
        # This also accepts `Hash` and `Array`
        # and return false for collection matching
        class ArrayWithSize < Expectations::Mixins::BuiltIn::ArrayWithSize
          # `Fixnum` & `Bignum` will be returned instead of `Integer`
          # in `#class` for numbers
          ADDITIONAL_EXPECTATION_CLASS_MAPPINGS = {
            Array   => ->(_) { Expectations::Private::Nothing::INSTANCE },
            Hash    => ->(_) { Expectations::Private::Nothing::INSTANCE },
          }.freeze
          private_constant :ADDITIONAL_EXPECTATION_CLASS_MAPPINGS

          class << self
            private

            # Overrides
            # {Expectations::Mixins::BuiltIn::ArrayWithSize.
            # expectation_classes_mappings}
            #
            # @return [Hash]
            def expectation_classes_mappings
              super.merge(
                ADDITIONAL_EXPECTATION_CLASS_MAPPINGS,
              )
            end
          end
        end
      end
    end
  end
end
