require "abstract_class"

module RSpec
  module JsonMatchers
    # Represents an expectation of an object (usually called `expected`)
    # Built to avoid {Object#===} usage like other matcher gems,
    # like `rspec-json_matcher`
    # Actually `rspec-mocks` `3.x` also uses it, but only internally
    #
    # @api
    #   This class can be extended to create custom kinds of expectation
    #   But only used for this gem
    # @abstract
    #   This class MUST be used after being inherited
    #   Subclasses MUST override {#expect?}
    #   to allow this gem to determine the test result
    class Expectation
      extend AbstractClass

      # @abstract
      #   This method MUST be overridden
      #   to allow this gem to determine the test result
      #
      # @param value [Object] actual value to be evaluated
      #
      # @return [Bool] Whether the `value` is expected
      def expect?(_value)
        fail NotImplementedError
      end

      class << self
        # @api private
        #
        # "Build" an expectation object (not class) depends on `value`
        #
        # @param value [Object]
        #   expected value, could be an expectation object as well
        #
        # @return [Expectation]
        def build(value)
          return value if value.is_a?(self)

          if value.is_a?(Regexp)
            return Expectations::Private::MatchingRegexp[value]
          end

          return Expectations::Private::InRange[value] if value.is_a?(Range)

          if value.respond_to?(:call)
            return Expectations::Private::SatisfyingCallable[value]
          end

          if value.is_a?(Class)
            # Subclass
            # See http://ruby-doc.org/core-2.2.2/Module.html#method-i-3C
            if value < Expectations::Core::SingletonExpectation
              return value::INSTANCE
            end
            return Expectations::Private::KindOf[value]
          end

          Expectations::Private::Eq[value]
        end
        # @api private
        #
        # "Build" expectation objects (not classes) depending on `values`
        #
        # @return [Array<Expectation>]
        # @see .build
        def build_many(values)
          values.flat_map { |v| build(v) }
        end
      end
    end
  end
end

# Classes in the following file(s) are required at runtime not parse time
require_relative "expectations"
