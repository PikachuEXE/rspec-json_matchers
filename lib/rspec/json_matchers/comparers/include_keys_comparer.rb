require_relative "abstract_comparer"

module RSpec
  module JsonMatchers
    module Comparers
      # @api private
      # @abstract
      class IncludeKeysComparer < AbstractComparer
        private

        # @note with side effect on `#reasons`
        def has_matched_keys?
          actual_keys = Utils::CollectionKeysExtractor.extract(actual)
          expected_keys = Utils::CollectionKeysExtractor.extract(expected)
          (expected_keys.subset?(actual_keys)).tap do |success|
            unless success
              diff_keys = (expected_keys - actual_keys)
              reasons.push(diff_keys.awesome_inspect)
            end
          end
        end
      end
    end
  end
end
