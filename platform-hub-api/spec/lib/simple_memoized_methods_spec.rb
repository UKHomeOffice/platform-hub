require 'rails_helper'

RSpec.describe SimpleMemoizedMethods do

  let(:klass) do
    Class.new do
      extend Memoist
      extend SimpleMemoizedMethods
      simple_memoized_methods :foo

      def build_foo
        :result
      end
    end
  end

  subject { klass.new }

  before do
    allow(subject).to receive(:build_foo).and_call_original
  end

  it 'should define a new instance method which calls the underlying build method only once' do
    expect(subject).to respond_to :foo

    expect(subject.foo).to eq :result  # Once
    expect(subject.foo).to eq :result  # Twice
    expect(subject.foo).to eq :result  # Three times a laaaady

    expect(subject).to have_received(:build_foo).once
  end

end
