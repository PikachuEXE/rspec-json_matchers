require "spec_helper"

RSpec.describe RSpec::JsonMatchers::Matchers::BeJsonWithContentMatcher do
  describe "with different expected values" do
    subject { actual.to_json }

    let(:actual) do
      {
        a: actual_value,
      }
    end
    let(:expected) do
      {
        a: expected_value,
      }
    end
    let(:actual_value) { fail NotImplementedError }
    let(:expected_value) { fail NotImplementedError }

    context "when expected value represents a valid JSON data type" do
      context "like `String`" do
        let(:actual_value) { "abc" }

        context "when they have equal classes and values" do
          let(:expected_value) { actual_value }

          it { should be_json.with_content(expected) }
        end

        context "when they have equal classes but diff values" do
          let(:expected_value) { actual_value.swapcase }

          it { should_not be_json.with_content(expected) }
        end

        context "when they have diff classes" do
          let(:expected_value) { 1 }

          it { should_not be_json.with_content(expected) }
        end
      end

      context "like `Number`" do
        let(:actual_value) { 1 }

        context "when they have equal classes and values" do
          let(:expected_value) { actual_value }

          it { should be_json.with_content(expected) }
        end

        context "when they have equal classes but diff values" do
          let(:expected_value) { actual_value + 1 }

          it { should_not be_json.with_content(expected) }
        end

        context "when they have diff classes" do
          let(:expected_value) { actual_value.to_s }

          it { should_not be_json.with_content(expected) }
        end
      end

      context "like `true`" do
        let(:actual_value) { true }

        context "when they have equal classes and values" do
          let(:expected_value) { actual_value }

          it { should be_json.with_content(expected) }
        end

        context "when they have equal classes but diff values" do
          let(:expected_value) { !actual_value }

          it { should_not be_json.with_content(expected) }
        end

        context "when they have diff classes" do
          let(:expected_value) { actual_value.to_s }

          it { should_not be_json.with_content(expected) }
        end
      end

      context "like `false`" do
        let(:actual_value) { false }

        context "when they have equal classes and values" do
          let(:expected_value) { actual_value }

          it { should be_json.with_content(expected) }
        end

        context "when they have equal classes but diff values" do
          let(:expected_value) { !actual_value }

          it { should_not be_json.with_content(expected) }
        end

        context "when they have diff classes" do
          let(:expected_value) { actual_value.to_s }

          it { should_not be_json.with_content(expected) }
        end
      end

      context "like `Array`" do
        let(:actual_value) { Array("abc") }

        context "when they have equal classes and values" do
          let(:expected_value) { actual_value }

          it { should be_json.with_content(expected) }
        end

        context "when they have equal classes but diff values" do
          let(:expected_value) { actual_value.map(&:swapcase) }

          it { should_not be_json.with_content(expected) }
        end

        context "when they have diff classes" do
          let(:expected_value) { actual_value.map { |_| 1 } }

          it { should_not be_json.with_content(expected) }
        end
      end

      context "like `Object`" do
        let(:actual_value) { { a: "abc" } }

        context "when they have equal classes and values" do
          let(:expected_value) { actual_value }

          it { should be_json.with_content(expected) }
        end

        # https://stackoverflow.com/questions/5189161/changing-every-value-in-a-hash-in-ruby
        context "when they have equal classes but diff values" do
          let(:expected_value) do
            Hash[actual_value.map { |k, v| [k, v.swapcase] }]
          end

          it { should_not be_json.with_content(expected) }
        end

        context "when they have diff classes" do
          let(:expected_value) do
            Hash[actual_value.map { |k, _| [k, 1] }]
          end

          it { should_not be_json.with_content(expected) }
        end
      end
    end

    context "when expected value is `Regexp`" do
      let(:expected_value) { %r{^http://} }

      context "when actual is NOT a `String`" do
        let(:actual_value) { 1 }

        it { should_not be_json.with_content(expected) }
      end

      context "when actual IS a `String` and does NOT match expected" do
        let(:actual_value) { "https://domain.com" }

        it { should_not be_json.with_content(expected) }
      end

      context "when actual IS a `String` and DOES match expected" do
        let(:actual_value) { "http://domain.com" }

        it { should be_json.with_content(expected) }
      end
    end

    context "when expected value is `Range`" do
      let(:expected_value) { range }
      let(:range) { (1..10) }

      context "actual value is NOT covered by the range" do
        let(:actual_value) { range.begin - 1 }

        it "does NOT match" do
          should_not be_json.with_content(expected)
        end
      end
      context "actual value IS covered by the range" do
        let(:actual_value) { range.begin }

        it "DOES match" do
          should be_json.with_content(expected)
        end
      end
    end

    describe "when expected value is callable" do
      let(:expected_value) { callable }
      let(:actual_value) { "whatever" }
      let(:callable) { fail NotImplementedError }

      context "when expected is a `Proc`" do
        let(:callable) { ->(_) { callable_return_value } }
        let(:callable_return_value) { fail NotImplementedError }

        context "when expected returned false" do
          let(:callable_return_value) { false }

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end

        context "when expected returned true" do
          let(:callable_return_value) { true }

          it "DOES match" do
            should be_json.with_content(expected)
          end
        end
      end

      context "when expected is NOT a `Proc`, and respond_to `#call`" do
        context "and it's an instance of a custom class" do
          let(:callable) do
            instance_double("CallableInstance",
              call: callable_return_value
            )
          end
          let(:callable_return_value) { fail NotImplementedError }

          context "when expected returned false" do
            let(:callable_return_value) { false }

            it "does NOT match" do
              should_not be_json.with_content(expected)
            end
          end

          context "when expected returned true" do
            let(:callable_return_value) { true }

            it "DOES match" do
              should be_json.with_content(expected)
            end
          end
        end

        context "and it's a `Class`" do
          let(:callable_class) do
            class_double("CallableClass",
              call: callable_return_value
            )
          end
          let(:callable) { callable_class }
          let(:callable_return_value) { fail NotImplementedError }

          context "when expected returned false" do
            let(:callable_return_value) { false }

            it "does NOT match" do
              should_not be_json.with_content(expected)
            end
          end

          context "when expected returned true" do
            let(:callable_return_value) { true }

            it "DOES match" do
              should be_json.with_content(expected)
            end
          end
        end
      end
    end

    describe "when expected value is `Class` and do not respond to `.call`" do
      context "and the class is NOT a subclass of `SingletonExpectation`" do
        let(:expected_value) { klass }
        let(:actual_value) { 1 }
        let(:klass) { fail NotImplementedError }

        context "when class does NOT match the data type" do
          let(:klass) { String }

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end
        context "when class DOES match the data type" do
          let(:klass) { Integer }

          it "DOES match" do
            should be_json.with_content(expected)
          end
        end
        context "when class DOES match one of the data type's ancestors" do
          let(:klass) { Numeric }

          it "DOES match" do
            should be_json.with_content(expected)
          end
        end
      end
    end

    context "when expected value is an `Expectation` object or class" do
      describe "Expectations::Mixins::BuiltIn::Anything" do
        let(:expected_value) do
          RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::Anything
        end

        [
          {
            type: "String",
            actual: "ab",
          },
          {
            type: "Number (Integer)",
            actual: 1,
          },
          {
            type: "Number (Float)",
            actual: 1.1,
          },
          {
            type: "Array",
            actual: [],
          },
          {
            type: "Object",
            actual: {},
          },
          {
            type: "true",
            actual: true,
          },
          {
            type: "false",
            actual: false,
          },
          {
            type: "null",
            actual: nil,
          },
        ].each do |hash|
          context "and actual is a #{hash.fetch(:type)}" do
            let(:actual_value) { hash.fetch(:actual) }

            it "DOES match" do
              should be_json.with_content(expected)
            end
          end
        end
      end

      describe "Expectations::Mixins::BuiltIn::PositiveNumber" do
        let(:expected_value) do
          RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::PositiveNumber
        end

        [
          {
            type: "String",
            actual: "ab",
            should_match: false,
          },

          {
            type: "Number (Integer) (Positive)",
            actual: 1,
            should_match: true,
          },
          {
            type: "Number (Integer) (Zero)",
            actual: 0,
            should_match: false,
          },
          {
            type: "Number (Integer) (Negative)",
            actual: -1,
            should_match: false,
          },

          {
            type: "Number (Float) (Positive)",
            actual: 1.1,
            should_match: true,
          },
          {
            type: "Number (Float) (Zero)",
            actual: 0.0,
            should_match: false,
          },
          {
            type: "Number (Float) (Negative)",
            actual: -1.1,
            should_match: false,
          },

          {
            type: "Array",
            actual: [],
            should_match: false,
          },
          {
            type: "Object",
            actual: {},
            should_match: false,
          },

          {
            type: "true",
            actual: true,
            should_match: false,
          },
          {
            type: "false",
            actual: false,
            should_match: false,
          },

          {
            type: "null",
            actual: nil,
            should_match: false,
          },
        ].each do |hash|
          context "and actual is a #{hash.fetch(:type)}" do
            let(:actual_value) { hash.fetch(:actual) }

            if hash.fetch(:should_match)
              it "DOES match" do
                should be_json.with_content(expected)
              end
            else
              it "does NOT match" do
                should_not be_json.with_content(expected)
              end
            end
          end
        end
      end

      describe "Expectations::Mixins::BuiltIn::NegativeNumber" do
        let(:expected_value) do
          RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::NegativeNumber
        end

        [
          {
            type: "String",
            actual: "ab",
            should_match: false,
          },

          {
            type: "Number (Integer) (Positive)",
            actual: 1,
            should_match: false,
          },
          {
            type: "Number (Integer) (Zero)",
            actual: 0,
            should_match: false,
          },
          {
            type: "Number (Integer) (Negative)",
            actual: -1,
            should_match: true,
          },

          {
            type: "Number (Float) (Positive)",
            actual: 1.1,
            should_match: false,
          },
          {
            type: "Number (Float) (Zero)",
            actual: 0.0,
            should_match: false,
          },
          {
            type: "Number (Float) (Negative)",
            actual: -1.1,
            should_match: true,
          },

          {
            type: "Array",
            actual: [],
            should_match: false,
          },
          {
            type: "Object",
            actual: {},
            should_match: false,
          },

          {
            type: "true",
            actual: true,
            should_match: false,
          },
          {
            type: "false",
            actual: false,
            should_match: false,
          },

          {
            type: "null",
            actual: nil,
            should_match: false,
          },
        ].each do |hash|
          context "and actual is a #{hash.fetch(:type)}" do
            let(:actual_value) { hash.fetch(:actual) }

            if hash.fetch(:should_match)
              it "DOES match" do
                should be_json.with_content(expected)
              end
            else
              it "does NOT match" do
                should_not be_json.with_content(expected)
              end
            end
          end
        end
      end

      describe "Expectations::Mixins::BuiltIn::BooleanValue" do
        let(:expected_value) do
          RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::BooleanValue
        end

        [
          {
            type: "String",
            actual: "ab",
            should_match: false,
          },
          {
            type: "Number (Integer)",
            actual: 1,
            should_match: false,
          },
          {
            type: "Number (Float)",
            actual: 1.1,
            should_match: false,
          },
          {
            type: "Array",
            actual: [],
            should_match: false,
          },
          {
            type: "Object",
            actual: {},
            should_match: false,
          },

          {
            type: "true",
            actual: true,
            should_match: true,
          },
          {
            type: "false",
            actual: false,
            should_match: true,
          },

          {
            type: "null",
            actual: nil,
            should_match: false,
          },
        ].each do |hash|
          context "and actual is a #{hash.fetch(:type)}" do
            let(:actual_value) { hash.fetch(:actual) }

            if hash.fetch(:should_match)
              it "DOES match" do
                should be_json.with_content(expected)
              end
            else
              it "does NOT match" do
                should_not be_json.with_content(expected)
              end
            end
          end
        end
      end

      describe "Expectations::Mixins::BuiltIn::ArrayOf" do
        let(:expected_value) { expectation }
        # All equal to `1`
        let(:expectation) do
          RSpec::JsonMatchers::Expectations::
            Mixins::BuiltIn::ArrayOf[element_expectation]
        end
        let(:element_expectation) { 1 }

        context "when actual is NOT an Array" do
          let(:actual_value) { { a: 1 } }

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end

        context "when actual IS an Array" do
          context "and it IS empty" do
            let(:actual_value) { [] }

            context "and empty collection is allowed or not is NOT specified" do
              it "DOES match" do
                should be_json.with_content(expected)
              end
            end
            context "and empty collection is NOT allowed" do
              context "using #allow_empty" do
                let(:expected_value) { expectation.allow_empty(false) }

                it "does NOT match" do
                  should_not be_json.with_content(expected)
                end
              end
              context "using #disallow_empty" do
                let(:expected_value) { expectation.disallow_empty }

                it "does NOT match" do
                  should_not be_json.with_content(expected)
                end
              end
            end
            context "and empty collection IS allowed" do
              context "without argument" do
                let(:expected_value) { expectation.allow_empty }

                it "DOES match" do
                  should be_json.with_content(expected)
                end
              end
              context "with argument" do
                let(:expected_value) { expectation.allow_empty(true) }

                it "DOES match" do
                  should be_json.with_content(expected)
                end
              end
            end
          end

          context "and it is NOT empty" do
            context "and ONLY some elements match the expectation" do
              let(:actual_value) { [1, 2] }

              it "does NOT match" do
                should_not be_json.with_content(expected)
              end
            end
            context "and ALL elements match the expectation" do
              let(:actual_value) { [1, 1] }

              it "DOES match" do
                should be_json.with_content(expected)
              end
            end
          end
        end

        context "when an expectation is passed in" do
          context "and it is a class" do
            let(:element_expectation) do
              RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::BooleanValue
            end

            [
              {
                type: "true",
                actual: [true],
                should_match: true,
              },
              {
                type: "false",
                actual: [false],
                should_match: true,
              },
              {
                type: "null",
                actual: [nil],
                should_match: false,
              },
            ].each do |hash|
              context "and actual is a #{hash.fetch(:type)}" do
                let(:actual_value) { hash.fetch(:actual) }

                if hash.fetch(:should_match)
                  it "DOES match" do
                    should be_json.with_content(expected)
                  end
                else
                  it "does NOT match" do
                    should_not be_json.with_content(expected)
                  end
                end
              end
            end
          end
          context "and it is an object" do
            let(:element_expectation) do
              RSpec::JsonMatchers::Expectations::Private::Eq[1]
            end

            [
              {
                type: "value matching the expectation",
                actual: [1],
                should_match: true,
              },
              {
                type: "value NOT matching the expectation",
                actual: [2],
                should_match: false,
              },
            ].each do |hash|
              context "and actual is a #{hash.fetch(:type)}" do
                let(:actual_value) { hash.fetch(:actual) }

                if hash.fetch(:should_match)
                  it "DOES match" do
                    should be_json.with_content(expected)
                  end
                else
                  it "does NOT match" do
                    should_not be_json.with_content(expected)
                  end
                end
              end
            end
          end
        end
      end

      describe "Expectations::Mixins::BuiltIn::ArrayWithSize" do
        let(:expected_value) { expectation }
        # All equal to `1`
        let(:expectation) do
          RSpec::JsonMatchers::Expectations::
            Mixins::BuiltIn::ArrayWithSize[*expected_sizes]
        end
        let(:expected_sizes) { fail NotImplementedError }

        context "when actual is NOT an Array" do
          let(:expected_sizes) { [1] }
          let(:actual_value) { { a: 1 } }

          it "does NOT match" do
            should_not be_json.with_content(expected)
          end
        end

        context "when an expected size passed in" do
          context "and is an Integer" do
            let(:expected_sizes) { [1] }

            context "and actual does NOT match expected size" do
              let(:actual_value) { [:a] * (expected_sizes[0] + 1) }

              it "does NOT match" do
                should_not be_json.with_content(expected)
              end
            end
            context "and actual DOES match expected size" do
              let(:actual_value) { [:a] * expected_sizes[0] }

              it "DOES match" do
                should be_json.with_content(expected)
              end
            end
          end
          context "and is a Range" do
            let(:expected_sizes) { [(1..4)] }

            context "and actual does NOT match expected size" do
              let(:actual_value) { [:a] * (expected_sizes[0].end + 1) }

              it "does NOT match" do
                should_not be_json.with_content(expected)
              end
            end
            context "and actual DOES match expected size" do
              let(:actual_value) { [:a] * expected_sizes[0].begin }

              it "DOES match" do
                should be_json.with_content(expected)
              end
            end
          end
        end

        context "when multiple expected sizes passed in" do
          let(:expected_sizes) { [1, 2, 3] }

          context "and actual size does NOT match any of expected sizes" do
            let(:actual_value) { [1] * 4 }

            it "does NOT match" do
              should_not be_json.with_content(expected)
            end
          end
          context "and actual size DOES match any of expected sizes" do
            let(:actual_value) { [1] * 2 }

            it "DOES match" do
              should be_json.with_content(expected)
            end
          end
        end

        context "when an unexpected size passed in" do
          context "and it is the only one" do
            let(:expected_sizes) { [1.1] }

            it "raises error when unexpected expectation(s) passed in" do
              expect { expectation }.to raise_error(ArgumentError)
            end
          end
          context "and it is not the only one" do
            let(:expected_sizes) { [1, 2, 1.1] }

            it "raises error when unexpected expectation(s) passed in" do
              expect { expectation }.to raise_error(ArgumentError)
            end
          end
        end
      end

      describe "Expectations::Mixins::BuiltIn::AnyOf" do
        let(:expected_value) do
          RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::AnyOf[
            1,
            2,
            3,
          ]
        end

        [
          {
            type: "value matching >= 1 expectations",
            actual: 1,
            should_match: true,
          },
          {
            type: "value matching >= 1 expectations",
            actual: 2,
            should_match: true,
          },
          {
            type: "value matching >= 1 expectations",
            actual: 3,
            should_match: true,
          },
          {
            type: "value matching 0 expectation",
            actual: 4,
            should_match: false,
          },
          {
            type: "value matching 0 expectation and null",
            actual: nil,
            should_match: false,
          },
        ].each do |hash|
          context "and actual is a #{hash.fetch(:type)}" do
            let(:actual_value) { hash.fetch(:actual) }

            if hash.fetch(:should_match)
              it "DOES match" do
                should be_json.with_content(expected)
              end
            else
              it "does NOT match" do
                should_not be_json.with_content(expected)
              end
            end
          end
        end
      end

      describe "Expectations::Mixins::BuiltIn::AllOf" do
        let(:expected_value) do
          RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::AllOf[
            (1..10),
            (2..10),
            (3..10),
          ]
        end

        [
          {
            type: "value NOT matching ALL expectations",
            actual: 1,
            should_match: false,
          },
          {
            type: "value NOT matching ALL expectations",
            actual: 2,
            should_match: false,
          },
          {
            type: "value matching ALL expectations",
            actual: 3,
            should_match: true,
          },
        ].each do |hash|
          context "and actual is a #{hash.fetch(:type)}" do
            let(:actual_value) { hash.fetch(:actual) }

            if hash.fetch(:should_match)
              it "DOES match" do
                should be_json.with_content(expected)
              end
            else
              it "does NOT match" do
                should_not be_json.with_content(expected)
              end
            end
          end
        end
      end

      describe "Expectations::Mixins::BuiltIn::NullableOf" do
        let(:expected_value) do
          RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::NullableOf[
            1,
            2,
            3,
          ]
        end

        [
          {
            type: "value matching >= 1 expectations",
            actual: 1,
            should_match: true,
          },
          {
            type: "value matching >= 1 expectations",
            actual: 2,
            should_match: true,
          },
          {
            type: "value matching >= 1 expectations",
            actual: 3,
            should_match: true,
          },
          {
            type: "value matching 0 expectation",
            actual: 4,
            should_match: false,
          },
          {
            type: "value matching 0 expectation and null",
            actual: nil,
            should_match: true,
          },
        ].each do |hash|
          context "and actual is a #{hash.fetch(:type)}" do
            let(:actual_value) { hash.fetch(:actual) }

            if hash.fetch(:should_match)
              it "DOES match" do
                should be_json.with_content(expected)
              end
            else
              it "does NOT match" do
                should_not be_json.with_content(expected)
              end
            end
          end
        end
      end

      describe "Expectations::Mixins::BuiltIn::HashWithContent" do
        describe "#with_exact_keys" do
          subject { actual.to_json }

          let(:actual) do
            {
              a: 1,
            }
          end
          let!(:expected) do
            RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::HashWithContent[
              a: 1,
            ]
          end

          context "and subject is exactly matched with expected" do
            it "DOES match" do
              should be_json.with_content(expected.with_exact_keys)
            end
          end

          context "and subject has different content then expected" do
            let!(:expected) do
              RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::HashWithContent[
                a: 2,
              ]
            end

            it "does NOT match" do
              should_not be_json.with_content(expected.with_exact_keys)
            end
          end

          context "and expected has less keys than actual" do
            let!(:expected) do
              RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::HashWithContent[{
                # empty
              }]
            end

            it "does NOT match" do
              should_not be_json.with_content(expected.with_exact_keys)
            end
          end

          context "and subject and expected have some common properties" do
            context "and subject has more properties" do
              before { actual.merge!(b: 1) }

              it "does NOT match" do
                should_not be_json.with_content(expected.with_exact_keys)
              end
            end

            context "and expected has more properties" do
              context "and subject has more properties" do
                let!(:expected) do
                  RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::HashWithContent[
                    a: 1,
                    b: 1,
                  ]
                end

                it "does NOT match" do
                  should_not be_json.with_content(expected.with_exact_keys)
                end
              end
            end
          end
        end

        describe "handling of nested expectations" do
          subject { actual.to_json }

          let!(:expected) do
            RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::HashWithContent[
              object: RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::HashWithContent[
                bool:   RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::BooleanValue,
                number: RSpec::JsonMatchers::Expectations::Mixins::BuiltIn::PositiveNumber,
                string: /str/,
              ],
            ]
          end

          context "when property is NOT an object" do
            let(:actual) do
              {
                object: 1,
              }
            end

            it "does NOT match" do
              should_not be_json.with_content(expected.with_exact_keys)
            end
          end

          context "when property IS an object but missing some key" do
            let(:actual) do
              {
                object: {
                  bool:   true,
                  number: 1,
                },
              }
            end

            it "does NOT match" do
              should_not be_json.with_content(expected.with_exact_keys)
            end
          end

          context "when property IS an object but some value does not match expectation" do
            let(:actual) do
              {
                object: {
                  bool:   true,
                  number: 1,
                  string: "123",
                },
              }
            end

            it "does NOT match" do
              should_not be_json.with_content(expected.with_exact_keys)
            end
          end
        end
      end
    end
  end
end
