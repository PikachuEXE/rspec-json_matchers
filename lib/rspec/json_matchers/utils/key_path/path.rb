require_relative 'extraction'

module RSpec
  module JsonMatchers
    module Utils
      # @api private
      module KeyPath
        # Represents a path pointing to an element
        # of a {Hash} or {Array}
        class Path
          # The "path part" separator
          # Period is used since it's the least used char as part of a key name
          # (it can never by used for index anyway)
          # As a side effect this char CANNOT be used,
          # escaping is not planned to be added
          PATH_PART_SPLITTER = '.'.freeze
          # The regular expression for checking "invalid" path
          # The separator should NOT at the start/end of the string,
          # or repeating itself without other chars in between
          INVALID_PATH_REGEX = /
          (
          ^#{Regexp.escape(PATH_PART_SPLITTER)}
          |
          #{
            Regexp.escape(PATH_PART_SPLITTER)
          }{2,}
          |
          #{Regexp.escape(PATH_PART_SPLITTER)}$
          )
          /x
            .freeze

          # Creates a {Path}
          # with a {String} (mainly from external)
          # (will store it internally)
          # or a {Path} (mainly from internal)
          # (will get and assign the string path it internally)
          #
          # @note
          #   It does not copy the string object since there is not need
          #   This might lead to some strange bug
          #
          # @param path [String, Path]
          #   the path to be used
          #   {String} is mainly for external use, {Path} for internal use
          #
          # @raise [TypeError] when `path` is not a {String} or {Path}
          def initialize(path)
            case path
            when Path
              @string_path = path.string_path
            when String
              @string_path = path
            else
              fail TypeError, 'Only String and Path is expected'
            end
          end

          def valid?
            !invalid?
          end

          # Run a loop on all "path parts" without exposing the parts
          # a block is required
          #
          # @yieldparam part [String] a "path part" if the {#string_path}
          #
          # @return [Path] The path object itself
          def each_path_part(&block)
            path_parts.each(&block)
            self
          end

          # Return successful extraction result when path is empty
          # Return failed extraction result when path is invalid
          # Delegate to {Extractor} otherwise
          #
          # @param object [Object]
          #   The "source object" to extract our "target object" from
          #
          # @return [Extraction::Result] The result of object extraction
          def extract(object)
            return Extraction::Result.new(object, true) if empty?
            return Extraction::Result.new(object, false) if invalid?

            Extraction.new(object, self).extract
          end

          protected

          attr_reader :string_path

          private

          def path_parts
            string_path.split(PATH_PART_SPLITTER)
          end

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
