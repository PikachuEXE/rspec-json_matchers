require_relative "path"

module RSpec
  module JsonMatchers
    module Utils
      # @api private
      module KeyPath
        # Represents an extractor that performs the extraction
        # with a {#path} & {#object}
        class Extraction
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

            @failed = false
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
              result = extract_object_with_path_part(path_part)
              return Result.new(object, false) if result.failed?

              self.object = result.object
            end

            Result.new(object, true)
          end

          private

          attr_accessor(*[
            :object,
          ])
          attr_reader(*[
            :path,
            :failed,
          ])
          alias_method :failed?, :failed

          # @param path_part [String]
          #   One part of {#path}
          def extract_object_with_path_part(path_part)
            ExtractionWithOnePathPart.new(object, path_part).extract
          end

          def fail!
            @failed = true
            self
          end

          # @api private
          #
          # Internal implementation for an extraction operation with
          # only one part of the path
          class ExtractionWithOnePathPart
            # Create a new extractor with the "source object"
            # and the path to be used for extracting our target object
            #
            # @param object [Object]
            #   The source object to extract our target object from
            # @param path_part [String]
            #   a part of {KeyPath::Path} of target object
            def initialize(object, path_part)
              @object = object
              @path_part = path_part
            end

            # Actually perform the extraction and return the result
            # Since the object could be falsy,
            # an object of custom class is returned instead of the object only
            #
            # @return (see Extraction#extract)
            def extract
              case object
              when Hash
                extract_object_from_hash
              when Array
                extract_object_from_array
              else
                # Disallow non JSON collection type
                Result.new(object, false)
              end
            end

            private

            def extract_object_from_hash
              # Allow nil as object, but disallow key to be absent
              return Result.new(object, false) unless object.key?(path_part)

              Result.new(object.fetch(path_part), true)
            end

            def extract_object_from_array
              index = path_part.to_i
              # Disallow index to be out of range
              # Disallow negative number as index
              unless (path_part =~ /\A\d+\z/) && index < object.size
                return Result.new(object, false)
              end

              Result.new(object.slice(index), true)
            end

            attr_accessor(*[
              :object,
            ])
            attr_reader(*[
              :path_part,
            ])
          end

          # @api private
          #
          # Only as a value object for internal communication
          class Result
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
end
