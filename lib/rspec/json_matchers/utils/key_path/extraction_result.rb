module RSpec
  module JsonMatchers
    module Utils
      # @api private
      module KeyPath
        # Only as a value object
        class ExtractionResult
          attr_reader :object, :successful

          def initialize(object, successful)
            @object = object
            @successful = successful
          end

          def failed?
            !successful
          end
        end
      end
    end
  end
end
