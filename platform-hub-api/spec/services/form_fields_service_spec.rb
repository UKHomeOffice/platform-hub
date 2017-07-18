require 'rails_helper'

describe FormFieldsService, type: :service do

  let :some_valid_types do
    FormFieldsService.all_types.to_a.sample(2).to_set
  end

  describe '.all_types' do
    it 'should return all the allowed field types' do
      expect(FormFieldsService.all_types).to eq FormFieldsService::ALL_ALLOWED_TYPES
    end
  end

  describe '.validate_types' do
    context 'when all types specified are valid' do
      it 'should not throw an error and should return the types specified' do
        expect(FormFieldsService.validate_types(some_valid_types)).to be some_valid_types
      end
    end

    context 'when types specified contain an invalid type' do
      it 'should throw an error' do
        types = some_valid_types + Set['fooooo', 'baaaaaaah']
        expect {
          FormFieldsService.validate_types(types)
        }.to raise_error("Invalid form field type(s) specified")
      end
    end

    context 'when types specified is empty' do
      it 'should not throw an error and should return the types specified' do
        expect(FormFieldsService.validate_types(Set[])).to eq Set[]
      end
    end
  end

  describe '.field_schema' do
    it 'should set the provided field types as expected' do
      expect(FormFieldsService.field_schema(some_valid_types)['field_type']).to eq some_valid_types
    end
  end

end
