# frozen_string_literal: true

require_relative "expectations/core"
require_relative "expectations/private"
require_relative "expectations/mixins/built_in"

module RSpec
  module JsonMatchers
    # This module does not mean to have any expectation class
    # Use the structure like {Expectations::BuiltIn}
    #
    # @api private
    module Expectations
    end
  end
end
