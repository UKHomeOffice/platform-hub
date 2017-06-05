FactoryGirl.define do
  factory :contact_list_hash_record, class: HashRecord do
    sequence(:id) { |n| "c#{n}#{ContactList::HASH_RECORD_KEY_POSTFIX}" }
    scope 'contact_lists'
    data do
      { email_addresses: ['foo', 'bar'] }
    end
  end
end
