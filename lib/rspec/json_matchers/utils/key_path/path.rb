require_relative "extraction_result"
require_relative "extractor"

module RSpec
  module JsonMatchers
    module Utils
      # @api private
      module KeyPath
        class Path
          PATH_PART_SPLITTER = ".".freeze
          INVALID_PATH_REGEX = %r_(
          ^#{Regexp.escape(PATH_PART_SPLITTER)}
          |
          #{Regexp.escape(PATH_PART_SPLITTER)}{2,}
          |
          #{Regexp.escape(PATH_PART_SPLITTER)}$
          )_x.freeze

          attr_reader :string_path

          def initialize(path)
            case path
            when Path
              @string_path = path.string_path
            when String
              @string_path = path
            else
              raise TypeError, "Only String and Path is expected"
            end
          end

          def valid?
            !invalid?
          end

          def each_path_part(&block)
            path_parts.each(&block)
          end

          def path_parts
            string_path.split(PATH_PART_SPLITTER)
          end

          # Return successful extraction result when path is empty
          # Return failed extraction result when path is invalid
          # Delegate to {Extractor} otherwise
          #
          # @return [ExtractionResult] The result of object extraction
          def extract(object)
            return ExtractionResult.new(object, true) if empty?
            return ExtractionResult.new(object, false) if invalid?
            Extractor.new(object, self).extract
          end

          private

          def invalid?
            INVALID_PATH_REGEX =~ string_path
          end

          def empty?
            path_parts.empty?
          end

          def to_s
            string_path
          end
        end
      end
    end
  end
end
