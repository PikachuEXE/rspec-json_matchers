require "abstract_class"

require_relative "../expectation"

module RSpec
  module JsonMatchers
    module Expectations
      # @api
      #   All classes within module should be able to be used / extended
      #   Unless specified otherwise
      module Core
        # @abstract
        #   This class MUST be used after being inherited
        #   Subclasses will have a constant `INSTANCE` storing the only instance of that class
        # @note
        #   This class assumed descendants to NOT override {.inherited} or call `super` if overridden
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

          def self.[](*values)
            unless values.size == EXPECTED_VALUE_SIZE
              raise ArgumentError, "Exactly #{EXPECTED_VALUE_SIZE} argument is required"
            end
            super
          end
        end

        # Takes any number of objects and converts into expectation objects (if not already)
        #
        # @abstract
        class CompositeExpectation < CallableExpectation
          extend AbstractClass

          attr_reader :expectations

          def self.[](*values)
            super(build_many(values))
          end

          def initialize(expectations)
            @expectations = expectations
          end
        end
      end
    end
  end
end
