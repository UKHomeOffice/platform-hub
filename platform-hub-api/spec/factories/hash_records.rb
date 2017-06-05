FactoryGirl.define do
  factory :hash_record do
    sequence(:id) { |n| "hash_record_#{n}" }
    scope 'general'
    data do
      { bar: 'baz' }
    end
  end
end
