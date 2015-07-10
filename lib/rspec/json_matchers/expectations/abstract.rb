require "abstract_class"

require_relative "core"

module RSpec
  module JsonMatchers
    module Expectations
      # @api private
      #   All classes within module should NOT be able to be used directly / extended
      #
      # Classes in this namespace are depending on {Core}
      # and depended by some classes in {Expectations::Mixins::BuiltIn}
      # They are all abstract too, thus the naming, but might change
      # This namespace is created is to avoid require order problem when putting classes here in {Private}
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

          def expect?(value)
            value.is_a?(Numeric)
          end
        end

      end
    end
  end
end
