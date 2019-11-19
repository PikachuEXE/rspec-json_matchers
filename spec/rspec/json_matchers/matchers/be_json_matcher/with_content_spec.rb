# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RSpec::JsonMatchers::Matchers::BeJsonMatcher, '#with_content' do
  let(:expectations) { Module.new { include RSpec::JsonMatchers::Expectations::Mixins::BuiltIn } }

  before(:each) do
    expectations.constants.each do |expectation_klass_name|
      stub_const(expectation_klass_name.to_s, expectations.const_get(expectation_klass_name))
    end
  end

  context 'when subject is NOT valid JSON' do
    subject { '' }

    it 'does NOT match' do
      should_not be_json.with_content({})
    end
  end

  context 'when subject is valid JSON object' do
    subject { {}.to_json }

    context 'and expected type does NOT match' do
      it 'does NOT match' do
        should_not be_json.with_content([])
      end
    end
    context 'and expected type DOES match' do
      it 'DOES match' do
        should be_json.with_content({})
      end
    end
  end
  context 'when subject is valid JSON array' do
    subject { [].to_json }

    context 'and expected type does NOT match' do
      it 'does NOT match' do
        should_not be_json.with_content({})
      end
    end
    context 'and expected type DOES match' do
      it 'DOES match' do
        should be_json.with_content([])
      end
    end
  end

  describe 'validation of JSON object' do
    context 'with no nesting' do
      subject { actual.to_json }

      let(:actual) { { a: 1 } }
      let!(:expected) { HashWithContent[{ a: 1 }] }

      context 'and subject is exactly matched with expected' do
        it 'DOES match' do
          should be_json.with_content(expected)
        end
      end

      context 'and subject is exactly matched with expected with string keys' do
        let!(:expected) { HashWithContent[{ 'a' => 1 }] }

        it 'DOES match' do
          should be_json.with_content(expected)
        end
      end

      context 'and subject has different content then expected' do
        let!(:expected) { HashWithContent[{ a: 2 }] }

        it 'does NOT match' do
          should_not be_json.with_content(expected)
        end
      end

      context 'and expected has less keys than actual' do
        let!(:expected) { HashWithContent[{}] }

        it 'DOES match' do
          should be_json.with_content(expected)
        end
      end

      context 'and subject and expected have some common properties' do
        context 'and subject has more properties' do
          before { actual.merge!(b: 1) }

          it 'DOES match' do
            should be_json.with_content(expected)
          end
        end

        context 'and expected has more properties' do
          context 'and subject has more properties' do
            let!(:expected) { HashWithContent[{ a: 1, b: 1 }] }

            it 'does NOT match' do
              should_not be_json.with_content(expected)
            end
          end
        end
      end
    end

    context 'with max 2 levels deep' do
      subject { actual.to_json }

      let(:actual) { { a: { b: 1 } } }
      let!(:expected) { HashWithContent[{ a: HashWithContent[{ b: 1 }] }] }

      context 'and subject is exactly matched with expected' do
        it 'DOES match' do
          should be_json.with_content(expected)
        end
      end

      context 'and subject has different content then expected' do
        context 'the only difference is the content of the deepest key' do
          let!(:expected) { HashWithContent[{ a: HashWithContent[{ b: 2 }] }] }

          it 'does NOT match' do
            should_not be_json.with_content(expected)
          end
        end
        context 'the only difference is the nesting' do
          let!(:expected) { HashWithContent[{ a: 1 }] }

          it 'does NOT match' do
            should_not be_json.with_content(expected)
          end
        end
      end
    end

    context 'with max 3 levels deep' do
      subject { actual.to_json }

      let(:actual) { { a: { b: { c: 1 } } } }
      let!(:expected) { HashWithContent[{ a: HashWithContent[{ b: HashWithContent[{ c: 1 }] }] }] }

      context 'and subject is exactly matched with expected' do
        it 'DOES match' do
          should be_json.with_content(expected)
        end
      end

      context 'and subject has different content then expected' do
        context 'the only difference is the content of the deepest key' do
          let!(:expected) { HashWithContent[{ a: HashWithContent[{ b: HashWithContent[{ c: 2 }] }] }] }

          it 'does NOT match' do
            should_not be_json.with_content(expected)
          end
        end
        context 'the only difference is the nesting' do
          let!(:expected) { HashWithContent[{ a: HashWithContent[{ b: 2 }] }] }

          it 'does NOT match' do
            should_not be_json.with_content(expected)
          end
        end
      end
    end
  end
end
