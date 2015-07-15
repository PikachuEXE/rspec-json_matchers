module RSpec
  module JsonMatchers
    module Utils
      # @api private
      class CollectionKeysExtractor
        #
        # @param collection [Array, Hash]
        #
        # @return [Set] set of keys/indexes of the collection
        # @raise [TypeError] When `collection` is not one of expected types
        def self.extract(collection)
          new(collection).extract
        end

        COLLECTION_TYPE_TO_VALUE_EXTRACTION_PROC_MAP = {
          Array => -> (collection) { collection.each_index.to_a.to_set },
          Hash  => -> (collection) { collection.each_key.map(&:to_s).to_set },
        }.freeze
        private_constant :COLLECTION_TYPE_TO_VALUE_EXTRACTION_PROC_MAP

        attr_reader :collection

        def initialize(collection)
          @collection = collection
        end

        def extract
          COLLECTION_TYPE_TO_VALUE_EXTRACTION_PROC_MAP.
            fetch(collection.class) do
              fail TypeError
            end.call(collection)
        end
      end
    end
  end
end
