require "spec_helper"

RSpec.describe RSpec::JsonMatchers::Matchers::BeJsonMatcher do
  describe "#with_sizes" do
    context "when subject is NOT valid JSON" do
      subject { "" }

      it "does NOT match" do
        should_not be_json.with_sizes({})
      end
    end

    context "when subject is valid JSON object" do
      subject { {}.to_json }

      context "and expected type is an array" do
        it "does NOT match" do
          should_not be_json.with_sizes([])
        end
      end
      context "and expected type is a hash" do
        it "DOES match" do
          should be_json.with_sizes({})
        end
      end
      context "and expected type is an Integer" do
        it "does NOT match" do
          should_not be_json.with_sizes(0)
        end
      end
    end
    context "when subject is valid JSON array" do
      subject { [].to_json }

      context "and expected type is an array" do
        it "DOES match" do
          should be_json.with_sizes([])
        end
      end
      context "and expected type is a hash" do
        it "does NOT match" do
          should_not be_json.with_sizes({})
        end
      end
      context "and expected type is an Integer" do
        it "DOES match" do
          should be_json.with_sizes(0)
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
        let!(:expected) { actual.size }

        context "and subject has size same as expected" do
          it "does NOT match" do
            should_not be_json.with_sizes(1)
          end
        end

        context "and subject has size different than expected" do
          let!(:expected) { actual.size + 1 }

          it "does NOT match" do
            should_not be_json.with_sizes(expected)
          end
        end

        describe "handling of Array in expected" do
          let!(:expected) { [actual.size - 1, actual.size, actual.size + 1] }

          context "when actual size is NOT included in expected" do
            before { expected.delete(actual.size) }

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end

          context "when actual size is included in expected" do
            before { expect(expected).to include(actual.size) }

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
        end

        describe "handling of Range in expected" do
          context "when actual size is NOT covered by expected" do
            let(:expected) { ((actual.size + 1)..(actual.size + 2)) }

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end

          context "when actual size is covered by expected" do
            let(:expected) { ((actual.size - 1)..(actual.size + 1)) }

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
        end
      end

      context "with nesting" do
        context "with max 2 levels deep" do
          subject { actual.to_json }

          let(:actual) do
            {
              a: [
                1,
              ],
            }
          end
          let!(:expected) do
            {
              a: 1,
            }
          end

          context "and subject is exactly matched with expected" do
            it "DOES match" do
              should be_json.with_sizes(expected)
            end
          end

          context "and ONLY deepest key size is unexpected" do
            before do
              actual.merge!(
                a: [
                  actual.fetch(:a),
                  actual.fetch(:a),
                ].flat_map { |i| i },
              )
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
          context "and ONLY nesting level is unexpected" do
            before do
              actual.merge!(
                a: Marshal.load(Marshal.dump(actual)),
              )
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
          context "and ONLY deepest key size data type is unexpected" do
            before do
              actual.merge!(
                a: 1,
              )
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end

          context "and actual and expected have common keys" do
            context "and actual has more keys" do
              before do
                actual.merge!(
                  b: [1],
                )
              end

              it "DOES match" do
                should be_json.with_sizes(expected)
              end
            end
            context "and expected has more keys" do
              before do
                expected.merge!(
                  b: 1,
                )
              end

              it "does NOT match" do
                should_not be_json.with_sizes(expected)
              end
            end
          end
        end

        context "with max 3 levels deep" do
          subject { actual.to_json }

          let(:actual) do
            {
              a: {
                b: [
                  1,
                ],
              },
            }
          end
          let!(:expected) do
            {
              a: {
                b: 1,
              },
            }
          end

          context "and subject is exactly matched with expected" do
            it "DOES match" do
              should be_json.with_sizes(expected)
            end
          end

          context "and ONLY deepest key size is unexpected" do
            before do
              actual.merge!(
                a: [
                  actual.fetch(:a).fetch(:b),
                  actual.fetch(:a).fetch(:b),
                ].flat_map { |i| i },
              )
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
          context "and ONLY nesting level is unexpected" do
            before do
              actual.merge!(
                a: Marshal.load(Marshal.dump(actual)),
              )
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
          context "and ONLY deepest key size data type is unexpected" do
            before do
              # A hash instead of array
              actual.merge!(
                a: { b: 1 },
              )
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
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
        let!(:expected) { actual.size }

        context "and subject has size same as expected" do
          it "DOES match" do
            should be_json.with_sizes(expected)
          end
        end

        context "and subject has size different than expected" do
          let!(:expected) { actual.size + 1 }

          it "does NOT match" do
            should_not be_json.with_sizes(expected)
          end
        end

        # Deep nested array is assumed to be absent in result
        describe "handling of Array in expected" do
          let!(:expected) { [actual.size - 1, actual.size, actual.size + 1] }

          context "when actual size is NOT included in expected" do
            before { expected.delete(actual.size) }

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end

          context "when actual size is included in expected" do
            before { expect(expected).to include(actual.size) }

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
        end

        describe "handling of Range in expected" do
          context "when actual size is NOT covered by expected" do
            let(:expected) { ((actual.size + 1)..(actual.size + 2)) }

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end

          context "when actual size is covered by expected" do
            let(:expected) { ((actual.size - 1)..(actual.size + 1)) }

            it "DOES match" do
              should be_json.with_sizes(expected)
            end
          end
        end
      end

      context "with nesting" do
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
          let!(:expected) { actual.map(&:size) }

          context "and subject is exactly matched with expected" do
            it "DOES match" do
              should be_json.with_sizes(expected)
            end
          end

          context "and ONLY deepest key size is unexpected" do
            before do
              actual[0] = [
                actual.at(0),
                actual.at(0),
              ].flat_map { |i| i }
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
          context "and ONLY nesting level is unexpected" do
            before do
              actual[0] = Marshal.load(Marshal.dump(actual))
            end

            it "DOES match" do
              should be_json.with_sizes(expected)
            end
          end
          context "and ONLY deepest key size data type is unexpected" do
            before do
              # A hash instead of array
              actual[0] = { b: 1 }
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
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
          let!(:expected) { actual.map { |lv2_ary| lv2_ary.map(&:size) } }

          context "and subject is exactly matched with expected" do
            it "DOES match" do
              should be_json.with_sizes(expected)
            end
          end

          context "and ONLY deepest key size is unexpected" do
            before do
              actual[0][0] = [
                actual.at(0).at(0),
                actual.at(0).at(0),
              ].flat_map { |i| i }
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
          context "and ONLY nesting level is unexpected" do
            before do
              actual[0] = Marshal.load(Marshal.dump(actual))
            end

            it "DOES match" do
              should be_json.with_sizes(expected)
            end
          end
          context "and ONLY deepest key size data type is unexpected" do
            before do
              # A hash instead of array
              actual[0][0] = { b: 1 }
            end

            it "does NOT match" do
              should_not be_json.with_sizes(expected)
            end
          end
        end
      end
    end
  end
end
