require_relative "abstract_comparer"

module RSpec
  module JsonMatchers
    module Comparers
      # @api private
      #
      # The comparer class that disallow actual collection
      # to have more properties/elements than expected collection
      class ExactKeysComparer < AbstractComparer
        private

        # @note with side effect on `#reasons`
        def has_matched_keys?
          (actual_keys == expected_keys).tap do |success|
            reasons.push(diff_keys.awesome_inspect) unless success
          end
        end

        def diff_keys
          (actual_keys - expected_keys) +
            (expected_keys - actual_keys)
        end
      end
    end
  end
end
