require "spec_helper"

RSpec.describe RSpec::JsonMatchers::Matchers::BeJsonMatcher, "#with_content" do
  context "when subject is NOT valid JSON" do
    subject { "" }

    it "does NOT match" do
      should_not be_json.with_content({})
    end
  end

  context "when subject is valid JSON object" do
    subject { {}.to_json }

    context "and expected type does NOT match" do
      it "does NOT match" do
        should_not be_json.with_content([])
      end
    end
    context "and expected type DOES match" do
      it "DOES match" do
        should be_json.with_content({})
      end
    end
  end
  context "when subject is valid JSON array" do
    subject { [].to_json }

    context "and expected type does NOT match" do
      it "does NOT match" do
        should_not be_json.with_content({})
      end
    end
    context "and expected type DOES match" do
      it "DOES match" do
        should be_json.with_content([])
      end
    end
  end

  describe "validation of JSON object" do
    context "with no nesting" do
      subject { actual.to_json }

      let(:actual) do
        {
          a: 1,
        }
      end
      let!(:expected) { actual.dup }

      context "and subject is exactly matched with expected" do
        it "DOES match" do
          should be_json.with_content(expected)
        end
      end

      context "and subject is exactly matched with expected with string keys" do
        before { expected.merge!("a" => expected.delete(:a)) }

        it "DOES match" do
          should be_json.with_content(expected)
        end
      end

      context "and subject has different content then expected" do
        before { expected.merge!(a: 2) }

        it "does NOT match" do
          should_not be_json.with_content(expected)
        end
      end

      context "and expected has less keys than actual" do
        before { expected.delete(:a) }

        it "DOES match" do
          should be_json.with_content(expected)
        end
      end

      context "and subject and expected have some common properties" do
        context "and subject has more properties" do
          before { actual.merge!(b: 1) }

          it "DOES match" do
            should be_json.with_content(expected)
          end
        end

        context "and expected has more properties" do
          context "and subject has more properties" do
            before { expected.merge!(b: 1) }

            it "does NOT match" do
              should_not be_json.with_content(expected)
            end
          end
        end
      end
    end

    context "with max 2 levels deep" do
      subject { actual.to_json }

      let(:actual) do
        {
          a: {
            b: 1,
          },
        }
      end
      let!(:expected) { actual.dup }

      context "and subject is exactly matched with expected" do
        it "DOES match" do
          should be_json.with_content(expected)
        end
      end

      context "and subject has different content then expected" do
        context "the only difference is the content of the deepest key" do
          before do
            expected.merge!(
              a: expected.fetch(:a).merge(b: 2),
            )
          end

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end
        context "the only difference is the nesting" do
          before do
            expected.merge!(
              a: 1,
            )
          end

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end
      end
    end

    context "with max 3 levels deep" do
      subject { actual.to_json }

      let(:actual) do
        {
          a: {
            b: {
              c: 1,
            },
          },
        }
      end
      let!(:expected) { actual.dup }

      context "and subject is exactly matched with expected" do
        it "DOES match" do
          should be_json.with_content(expected)
        end
      end

      context "and subject has different content then expected" do
        context "the only difference is the content of the deepest key" do
          before do
            expected.merge!(
              a: expected.fetch(:a).fetch(:b).merge(c: 2),
            )
          end

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end
        context "the only difference is the nesting" do
          before do
            expected.merge!(
              a: expected.fetch(:a).merge(b: 2),
            )
          end

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end
      end
    end
  end

  describe "validation of JSON array" do
    context "with no nesting" do
      subject { actual.to_json }

      let(:actual) do
        [
          1,
        ]
      end
      let!(:expected) { actual.dup }

      context "and subject is exactly matched with expected" do
        it "DOES match" do
          should be_json.with_content(expected)
        end
      end

      context "and subject has different content then expected" do
        before { expected[0] = 2 }

        it "does NOT match" do
          should_not be_json.with_content(expected)
        end
      end

      context "and expected has less keys than actual" do
        before { expected.delete_at(0) }

        it "DOES match" do
          should be_json.with_content(expected)
        end
      end

      context "and subject and expected have some common properties" do
        context "and subject has more properties" do
          before { actual[1] = 1 }

          it "DOES match" do
            should be_json.with_content(expected)
          end
        end

        context "and expected has more properties" do
          context "and subject has more properties" do
            before { expected[1] = 1 }

            it "does NOT match" do
              should_not be_json.with_content(expected)
            end
          end
        end
      end
    end

    context "with max 2 levels deep" do
      subject { actual.to_json }

      let(:actual) do
        [
          [
            1,
          ],
        ]
      end
      # Cannot find better alternative
      # But we only put simple values inside `actual`
      let!(:expected) { Marshal.load(Marshal.dump(actual)) }

      context "and subject is exactly matched with expected" do
        it "DOES match" do
          should be_json.with_content(expected)
        end
      end

      context "and subject has different content then expected" do
        context "the only difference is the content of the deepest key" do
          before do
            expected[0] = expected[0].tap do |a|
              a[0] = a[0] + 1
            end
          end

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end
        context "the only difference is the nesting" do
          before do
            expected[0] = 1
          end

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end
      end
    end

    context "with max 3 levels deep" do
      subject { actual.to_json }

      let(:actual) do
        [
          [
            [
              1,
            ],
          ],
        ]
      end
      # Cannot find better alternative
      # But we only put simple values inside `actual`
      let!(:expected) { Marshal.load(Marshal.dump(actual)) }

      context "and subject is exactly matched with expected" do
        it "DOES match" do
          should be_json.with_content(expected)
        end
      end

      context "and subject has different content then expected" do
        context "the only difference is the content of the deepest key" do
          before do
            expected[0] = expected[0].tap do |a1|
              a1[0] = a1[0].tap do |a2|
                a2[0] = a2[0] + 1
              end
            end
          end

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end
        context "the only difference is the nesting" do
          before do
            expected[0] = expected[0].tap do |a1|
              a1[0] = 1
            end
          end

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end
      end
    end
  end
end
