require "spec_helper"

RSpec.describe RSpec::JsonMatchers::Matchers::BeJsonWithSizesMatcher, "#at_path" do
  let(:content) { Array.new(1) { "whatever" } }

  context "when subject is valid JSON object" do
    subject do
      {
        a: {
          b: {
            c: content,
          },
        },
      }.to_json
    end

    describe "the matcher works similar to passing a deeply nested Hash in expected, with or without #at_path" do
      it { should be_json.with_sizes({a: {b: {c: 1}}}) }
      it { should be_json.with_sizes({b: {c: 1}}).at_path("a") }
      it { should be_json.with_sizes({c: 1}).at_path("a.b") }
      it { should be_json.with_sizes(1).at_path("a.b.c") }
    end

    describe "the matcher fails the example when no data is on the path" do
      it { should_not be_json.with_sizes(1).at_path("a.b.d") }
      it { should_not be_json.with_sizes(1).at_path("a.b.c.d") }
    end

    describe "the matcher fails the example when path is invalid" do
      it { expect(be_json.with_sizes(1).at_path(".").matches?(subject)).to eq false }
      it { expect(be_json.with_sizes(1).at_path(".a.").matches?(subject)).to eq false }
      it { expect(be_json.with_sizes(1).at_path("a..c").matches?(subject)).to eq false }

      it { expect(be_json.with_sizes(1).at_path(".").does_not_match?(subject)).to eq false }
      it { expect(be_json.with_sizes(1).at_path(".a.").does_not_match?(subject)).to eq false }
      it { expect(be_json.with_sizes(1).at_path("a..c").does_not_match?(subject)).to eq false }
    end

    context "the matcher works the example when subject is an object with digit (as String) in keys" do
      subject do
        {
          '1' => {
            '2' => content,
          },
        }.to_json
      end

      it { should be_json.with_sizes({'2' => 1}).at_path("1") }
      it { should be_json.with_sizes(1).at_path("1.2") }
    end
  end

  context "when subject is valid JSON array" do
    subject do
      [
        [
          [
            [
              content,
            ],
          ],
        ],
      ].to_json
    end

    describe "the matcher works similar to passing a deeply nested Hash in expected, with or without #at_path" do
      it { should be_json.with_sizes([[[[1]]]]) }

      it { should be_json.with_sizes([[[1]]]).at_path("0") }
      it { should be_json.with_sizes([[1]]).at_path("0.0") }
      it { should be_json.with_sizes([1]).at_path("0.0.0") }
      it { should be_json.with_sizes(1).at_path("0.0.0.0") }
    end

    describe "the matcher fails the example when no data is on the path" do
      it { should_not be_json.with_sizes(1).at_path("0.0.0.1") }
      it { should_not be_json.with_sizes(1).at_path("0.0.0.0.0") }
    end

    describe "the matcher fails the example when path is invalid" do
      it { expect(be_json.with_sizes(1).at_path(".").matches?(subject)).to eq false }
      it { expect(be_json.with_sizes(1).at_path(".0.").matches?(subject)).to eq false }
      it { expect(be_json.with_sizes(1).at_path("0..0").matches?(subject)).to eq false }

      it { expect(be_json.with_sizes(1).at_path(".").does_not_match?(subject)).to eq false }
      it { expect(be_json.with_sizes(1).at_path(".0.").does_not_match?(subject)).to eq false }
      it { expect(be_json.with_sizes(1).at_path("0..0").does_not_match?(subject)).to eq false }
    end

    describe "the matcher fails the example when path is invalid due to containing non-digit" do
      it { expect(be_json.with_sizes("whatever").at_path("a").matches?(subject)).to eq false }

      it { expect(be_json.with_sizes("whatever").at_path("a").does_not_match?(subject)).to eq true }
    end
  end
end
