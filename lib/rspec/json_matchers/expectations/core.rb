require "abstract_class"

require_relative "../expectation"

module RSpec
  module JsonMatchers
    module Expectations
      # @api
      #   All classes within module should be able to be used / extended
      #   Unless specified otherwise
      #
      # All public expectation classes that can be extended
      # even by classes in extension gems
      module Core
        # @abstract
        #   This class MUST be used after being inherited
        #   Subclasses will have a constant `INSTANCE`
        #   storing the only instance of that class
        # @note
        #   This class assumed descendants to NOT
        #   override {.inherited} or call `super` if overridden
        #   Otherwise the constant `INSTANCE` won't work
        # @note
        #   The constant `INSTANCE` will be referred with namespace,
        #   which eliminates the possibility of using parent class constant
        # @see
        #   https://stackoverflow.com/questions/3174563/how-to-use-an-overridden-constant-in-an-inheritanced-class
        # @note
        #   Pattern comes from gem rspec-mocks
        # @see
        #   https://github.com/rspec/rspec-mocks/blob/3-2-maintenance/lib/rspec/mocks/argument_matchers.rb
        class SingletonExpectation < Expectation
          extend AbstractClass

          private_class_method :new

          def self.inherited(subclass)
            subclass.const_set(:INSTANCE, subclass.send(:new))
          end
        end

        # Allow class to be called with `.[]` instead of `.new`
        #
        # @abstract
        #   This class MUST be used after being inherited
        class CallableExpectation < Expectation
          extend AbstractClass

          # The replacement of {.new}
          # It accept any number of arguments and delegates to private {.new}
          # This pattern is taken from gem `contracts`
          #
          # @see https://github.com/egonSchiele/contracts.ruby
          #
          # @return [Expectation] an expectation object
          def self.[](*values)
            new(*values)
          end

          private_class_method :new
        end

        # Validates exactly one value is passed in
        #
        # @abstract
        class SingleValueCallableExpectation < CallableExpectation
          EXPECTED_VALUE_SIZE = 1
          private_constant :EXPECTED_VALUE_SIZE

          # (see CallableExpectation.[])
          # But only 1 argument is accepted
          def self.[](*values)
            unless values.size == EXPECTED_VALUE_SIZE
              fail(
                ArgumentError,
                "Exactly #{EXPECTED_VALUE_SIZE} argument is required",
              )
            end
            super
          end
        end

        # Takes any number of objects and
        # converts into expectation objects (if not already)
        #
        # @abstract
        class CompositeExpectation < CallableExpectation
          extend AbstractClass

          # (see CallableExpectation.[])
          # Also all values will be converted into expectations
          def self.[](*values)
            super(build_many(values))
          end

          private

          attr_reader :expectations

          def initialize(expectations)
            @expectations = expectations
          end
        end
      end
    end
  end
end
