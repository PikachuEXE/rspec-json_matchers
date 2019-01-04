# frozen_string_literal: true

require "spec_helper"

describe RSpec::JsonMatchers do
  it "has a version number" do
    expect(RSpec::JsonMatchers::VERSION).not_to eq(nil)
  end
end
