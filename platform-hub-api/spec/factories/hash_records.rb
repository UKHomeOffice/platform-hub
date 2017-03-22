FactoryGirl.define do
  factory :hash_record do
    id 'foo'
    scope 'general'
    data do
      { bar: 'baz' }
    end
  end
end
