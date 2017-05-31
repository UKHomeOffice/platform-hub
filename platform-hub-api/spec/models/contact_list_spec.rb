require 'rails_helper'

RSpec.describe ContactList, type: :model do

  let(:id) { 'foo' }

  let :email_addresses do
    [
      'foo@example.com',
      'bar'
    ]
  end

  describe 'create then update flow' do
    it 'should manipulate an underlying HashRecord as expected' do
      expect(HashRecord.count).to eq 0

      contact_list = ContactList.find id
      expect(contact_list).not_to be nil
      expect(contact_list.id).to eq id
      expect(contact_list.email_addresses).to eq []
      expect(HashRecord.count).to eq 1
      hash_record = HashRecord.first
      expect(hash_record).to eq HashRecord.new(
        id: "#{id}#{ContactList::HASH_RECORD_KEY_POSTFIX}",
        scope: 'contact_lists',
        data: { 'email_addresses' => [] }
      )

      contact_list.update email_addresses: email_addresses
      expect(contact_list.email_addresses).to eq email_addresses
      expect(HashRecord.count).to eq 1
      hash_record = HashRecord.first
      expect(hash_record.data).to eq({ 'email_addresses' => email_addresses })
    end
  end

  describe '.find' do
    it 'should find an existing HashRecord and return a ContactList' do
      expect(HashRecord.count).to eq 0

      # First find should create it
      contact_list = ContactList.find id
      expect(contact_list).not_to be nil
      expect(contact_list.id).to eq id
      expect(HashRecord.count).to eq 1

      # Second find should retrieve the existing one
      contact_list_again = ContactList.find id
      expect(contact_list_again).to eq contact_list
      expect(HashRecord.count).to eq 1
    end
  end

end
