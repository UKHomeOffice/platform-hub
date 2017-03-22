require 'rails_helper'

RSpec.describe HashRecord, type: :model do

  describe 'a valid HashRecord instance' do

    before do
      @record = create :hash_record
    end

    it 'should persist as expected' do

      expect(HashRecord.count).to eq 1

      record = HashRecord.first
      expect(record.id).to eq @record.id
      expect(record.scope).to eq @record.scope
      expect(record.data).not_to be_empty
      expect(record.data).to eq @record.data

    end

  end

end
