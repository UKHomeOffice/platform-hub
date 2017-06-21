FactoryGirl.define do
  factory :contact_list do
    sequence(:id) { |n| "list_#{n}" }
    email_addresses do
      [ 'foo@example.org', 'bar@example.org' ]
    end
  end
end
