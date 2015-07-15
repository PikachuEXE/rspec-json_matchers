module RSpec
  module JsonMatchers
    module Comparers
      # @api private
      #
      # A value object returned by comparers
      # Instead of just Boolean
      class ComparisonResult
        attr_reader :reasons

        def initialize(matched, reasons)
          @matched = matched
          @reasons = reasons
        end

        def matched?
          @matched
        end
      end
    end
  end
end
