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

      # Determine the value passed in
      # is "expected" by self or not
      # And return the result
      #
      # @abstract
      #   This method MUST be overridden
      #   to allow this gem to determine the test result
      #
      # @param _value [Object] actual value to be evaluated
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
          Builder.new(value).build
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

      # @api private
      #
      # Represents a builder that
      # returns a {Expectation} object from an input object
      class Builder
        # Creates a bullder with an object that
        # might or might not be a {Expectation} object
        #
        # @param object [Object]
        #   any object that should be "built"
        #   into a {Expectation} object
        def initialize(object)
          @object = object
        end

        # Create and return a {Expectation} object
        # according to one of the following
        #   - the class of object
        #   - does the object respond to `#call`
        #   - the ancestors of the object (when it's a class)
        #
        # @return [Expectation] a {Expectation} object
        def build
          return object if object.is_a?(Expectation)
          return expectation_by_class unless expectation_by_class.nil?
          return expectation_for_call if object.respond_to?(:call)
          return expectation_by_ancestors if object.is_a?(Class)

          Expectations::Private::Eq[object]
        end

        private

        OBJECT_CLASS_TO_EXPECTATION_HASH = {
          Regexp => ->(obj) { Expectations::Private::MatchingRegexp[obj] },
          Range => ->(obj) { Expectations::Private::InRange[obj] },
          Hash => ->(obj) { Expectations::Mixins::BuiltIn::HashWithContent[obj] },
        }.freeze
        private_constant :OBJECT_CLASS_TO_EXPECTATION_HASH

        attr_reader(
          :object,
        )

        def expectation_by_class
          if instance_variable_defined?(:@expectation_by_object_class)
            return @expectation_by_object_class
          end

          proc = OBJECT_CLASS_TO_EXPECTATION_HASH[object.class]
          return nil if proc.nil?

          # Assign (cache) and return
          @expectation_by_object_class = proc.call(object)
        end

        def expectation_by_ancestors
          # Subclass
          # See http://ruby-doc.org/core-2.2.2/Module.html#method-i-3C
          if object < Expectations::Core::SingletonExpectation
            return object::INSTANCE
          end
          Expectations::Private::KindOf[object]
        end

        def expectation_for_call
          Expectations::Private::SatisfyingCallable[object]
        end
      end
    end
  end
end

# Classes in the following file(s) are required at runtime not parse time
require_relative "expectations"
