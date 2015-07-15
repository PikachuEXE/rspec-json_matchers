require "spec_helper"

RSpec.describe RSpec::JsonMatchers::Matchers::BeJsonWithSizesMatcher do
  describe "with different expected values" do
    subject { actual.to_json }

    let(:actual) do
      {
        a: actual_value,
      }
    end
    let(:expected) do
      {
        a: expected_size,
      }
    end
    let(:actual_value) { fail NotImplementedError }
    let(:expected_value) { fail NotImplementedError }

    context "and is an Integer" do
      let(:expected_size) { 1 }

      context "and actual does NOT match expected size" do
        let(:actual_value) { [1] * (expected_size + 1) }

        it "does NOT match" do
          should_not be_json.with_sizes(expected)
        end
      end
      context "and actual DOES match expected size" do
        let(:actual_value) { [1] * expected_size }

        it "DOES match" do
          should be_json.with_sizes(expected)
        end
      end
    end
    context "and is a Range" do
      let(:expected_size) { (1..4) }

      context "and actual does NOT match expected size" do
        let(:actual_value) { [1] * (expected_size.end + 1) }

        it "does NOT match" do
          should_not be_json.with_sizes(expected)
        end
      end
      context "and actual DOES match expected size" do
        let(:actual_value) { [1] * expected_size.begin }

        it "DOES match" do
          should be_json.with_sizes(expected)
        end
      end
    end
  end
end
