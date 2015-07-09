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
          actual_keys = Utils::CollectionKeysExtractor.extract(actual)
          expected_keys = Utils::CollectionKeysExtractor.extract(expected)
          (actual_keys == expected_keys).tap do |success|
            unless success
              diff_keys = (actual_keys - expected_keys) + (expected_keys - actual_keys)
              reasons.push(diff_keys.awesome_inspect)
            end
          end
        end
      end
    end
  end
end
