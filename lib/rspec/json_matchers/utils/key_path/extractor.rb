require_relative "path"

module RSpec
  module JsonMatchers
    module Utils
      # @api private
      module KeyPath
        class Extractor

          private
          attr_accessor *[
            :object,
          ]
          attr_reader *[
            :path,
          ]
          public

          #
          # @param object [Object]
          #
          # @return [ExtractionResult]
          def self.extract(object, path)
            new(object, path).extract
          end

          def initialize(object, path)
            @object = object
            @path = KeyPath::Path.new(path)
          end

          def extract
            path.each_path_part do |path_part|
              self.object = case object
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
        end
      end
    end
  end
end
