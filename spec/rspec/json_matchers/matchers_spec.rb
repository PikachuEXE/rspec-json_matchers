# frozen_string_literal: true

require "spec_helper"

RSpec.describe RSpec::JsonMatchers::Matchers do
  describe "#be_json" do
    context "when subject is NOT valid JSON" do
      subject { "" }

      it "does NOT match" do
        should_not be_json
      end
    end
    context "when subject is valid JSON object" do
      subject { {}.to_json }

      it "DOES match" do
        should be_json
      end
    end
    context "when subject is valid JSON array" do
      subject { [].to_json }

      it "DOES match" do
        should be_json
      end
    end
  end
end
