require "spec_helper"

RSpec.describe RSpec::JsonMatchers::Matchers::BeJsonWithContentMatcher, "#at_path" do
  let(:expectations) do
    Module.new do
      include RSpec::JsonMatchers::Expectations::Mixins::BuiltIn
    end
  end

  before(:each) do
    expectations.constants.each do |expectation_klass_name|
      stub_const(
        expectation_klass_name.to_s,
        expectations.const_get(expectation_klass_name),
      )
    end
  end

  context "when subject is valid JSON object" do
    subject do
      {
        a: {
          b: {
            c: 1,
          },
        },
      }.to_json
    end

    describe "the matcher works similar to passing a deeply nested Hash in expected, with or without #at_path" do
      it { should be_json.with_content({a: {b: {c: 1}}}) }
      it { should be_json.with_content({b: {c: 1}}).at_path("a") }
      it { should be_json.with_content({c: 1}).at_path("a.b") }
      it { should be_json.with_content(1).at_path("a.b.c") }
    end

    describe "the matcher fails the example when no data is on the path" do
      it { should_not be_json.with_content(Anything).at_path("a.b.d") }
      it { should_not be_json.with_content(Anything).at_path("a.b.c.d") }
    end

    describe "the matcher fails the example when there is data is on the path, and using `should_not`" do
      it { expect(be_json.with_content(Anything).at_path("a.b.c").does_not_match?(subject)).to eq false }
    end

    describe "the matcher fails the example when path is invalid" do
      it { expect(be_json.with_content(Anything).at_path(".").matches?(subject)).to eq false }
      it { expect(be_json.with_content(Anything).at_path(".a.").matches?(subject)).to eq false }
      it { expect(be_json.with_content(Anything).at_path("a..c").matches?(subject)).to eq false }

      it { expect(be_json.with_content(Anything).at_path(".").does_not_match?(subject)).to eq false }
      it { expect(be_json.with_content(Anything).at_path(".a.").does_not_match?(subject)).to eq false }
      it { expect(be_json.with_content(Anything).at_path("a..c").does_not_match?(subject)).to eq false }
    end

    context "the matcher works the example when subject is an object with digit (as String) in keys" do
      subject do
        {
          '1' => {
            '2' => 1,
          },
        }.to_json
      end

      it { should be_json.with_content({'2' => 1}).at_path("1") }
      it { should be_json.with_content(1).at_path("1.2") }
    end
  end

  context "when subject is valid JSON array" do
    subject do
      [
        [
          [
            1,
          ],
        ],
      ].to_json
    end

    describe "the matcher works similar to passing a deeply nested Hash in expected, with or without #at_path" do
      it { should be_json.with_content([[[1]]]) }

      it { should be_json.with_content([[1]]).at_path("0") }
      it { should be_json.with_content([1]).at_path("0.0") }
      it { should be_json.with_content(1).at_path("0.0.0") }
    end

    describe "the matcher fails the example when no data is on the path" do
      it { should_not be_json.with_content(Anything).at_path("0.0.1") }
      it { should_not be_json.with_content(Anything).at_path("0.0.0.0") }
    end

    describe "the matcher fails the example when there is data is on the path, and using `should_not`" do
      it { expect(be_json.with_content(Anything).at_path("0.0.0").does_not_match?(subject)).to eq false }
    end

    describe "the matcher fails the example when path is invalid" do
      it { expect(be_json.with_content(Anything).at_path(".").matches?(subject)).to eq false }
      it { expect(be_json.with_content(Anything).at_path(".0.").matches?(subject)).to eq false }
      it { expect(be_json.with_content(Anything).at_path("0..0").matches?(subject)).to eq false }

      it { expect(be_json.with_content(Anything).at_path(".").does_not_match?(subject)).to eq false }
      it { expect(be_json.with_content(Anything).at_path(".0.").does_not_match?(subject)).to eq false }
      it { expect(be_json.with_content(Anything).at_path("0..0").does_not_match?(subject)).to eq false }
    end

    describe "the matcher considers non-digit path as valid since subject is being checked later" do
      it { expect(be_json.with_content("whatever").at_path("a").matches?(subject)).to eq false }
      it { expect(be_json.with_content("whatever").at_path("a").does_not_match?(subject)).to eq true }
    end
  end
end
