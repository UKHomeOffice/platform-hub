require 'rails_helper'

RSpec.describe CSVHelper do

  subject { CSVHelper }

  describe '.validate_columns' do
    let :expected_columns do
      {
        foo: 0,
        bar: 2
      }
    end

    context 'with valid columns' do
      let(:header) { [ 'foo', 'other', 'bar' ] }

      it 'should not raise any errors' do
        expect {
          subject.validate_columns(header, expected_columns)
        }.not_to raise_error
      end
    end

    context 'with invalid columns' do
      let(:header) { [ 'foo', 'other' ] }

      it 'should raise an error for the mismatched column' do
        expect {
          subject.validate_columns(header, expected_columns)
        }.to raise_error(
          CSVHelper::ColumnError,
          "unexpected column at index 2 of header - should be 'bar' but got ''"
        )
      end
    end
  end

end
