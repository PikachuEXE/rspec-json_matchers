require_relative  "matchers/be_json_matcher"
require_relative  "matchers/be_json_with_content_matcher"
require_relative  "matchers/be_json_with_sizes_matcher"

module RSpec
  module JsonMatchers
    # Mixin Module to be included into RSpec
    # Other files will define the same module and add methods to this module
    module Matchers
    end
  end
end
