FactoryGirl.define do
  factory :user do
    id { SecureRandom.uuid }
    name { "Foo Bar #{id}" }
    email  { "#{name.gsub(' ', '').downcase}@example.com" }
    last_seen_at { Time.now }


    factory :admin_user do
      role 'admin'
    end
  end
end
