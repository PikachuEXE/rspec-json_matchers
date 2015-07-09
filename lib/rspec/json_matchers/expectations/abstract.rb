require "abstract_class"

require_relative "core"

module RSpec
  module JsonMatchers
    module Expectations
      # @api private
      #   All classes within module should NOT be able to be used directly / extended
      #   Classes with dependency on {Core} and depended by any class in {Expectations::Mixins::BuiltIn}
      module Abstract
        # @abstract
        #   Only for reducing code duplication
        #
        # Verifies the value passed in is a {Numeric}
        #
        # @note
        #   {Numeric} might not be the best class to check for
        #   Since not all subclasses of it are expected
        #   But for simplicity's sake this is used until problem raised
        class NumericExpectation < Expectations::Core::SingletonExpectation
          extend AbstractClass

          EXPECTED_VALUE_CLASS = Numeric

          def expect?(value)
            value.is_a?(EXPECTED_VALUE_CLASS)
          end
        end

      end
    end
  end
end
