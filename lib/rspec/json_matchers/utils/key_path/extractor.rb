require_relative "path"

module RSpec
  module JsonMatchers
    module Utils
      # @api private
      module KeyPath
        # Represents an extractor that performs the extraction
        # with a {#path} & {#object}
        class Extractor
          # Create a new extractor with the "source object"
          # and the path to be used for extracting our target object
          #
          # @param object [Object]
          #   The source object to extract our target object from
          # @param path [String, Path]
          #   the path of target object
          #   Will convert into {Path}
          #
          # @see JsonMatchers::Matchers::BeJsonWithSomethingMatcher#at_path
          def initialize(object, path)
            @object = object
            @path = KeyPath::Path.new(path)
          end

          # Actually perform the extraction and return the result
          # Since the object could be falsy,
          # an object of custom class is returned instead of the object only
          #
          # Assume the path to be valid
          #
          # @return (see Path#extract)
          def extract
            path.each_path_part do |path_part|
              self.object =
                case object
                when Hash
                  # Allow nil as object, but disallow key to be absent
                  unless object.key?(path_part)
                    return ExtractionResult.new(object, false)
                  end
                  object.fetch(path_part)
                when Array
                  index = path_part.to_i
                  # Disallow index to be out of range
                  # Disallow negative number as index
                  unless (path_part =~ /\A\d+\z/) && index < object.size
                    return ExtractionResult.new(object, false)
                  end
                  object.slice(index)
                else
                  # Disallow non JSON collection type
                  return ExtractionResult.new(object, false)
                end
            end

            ExtractionResult.new(object, true)
          end

          private

          attr_accessor(*[
            :object,
          ])
          attr_reader(*[
            :path,
          ])
        end
      end
    end
  end
end
