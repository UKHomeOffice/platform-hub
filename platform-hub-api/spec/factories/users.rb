FactoryGirl.define do
  factory :user do
    id { SecureRandom.uuid }
    name { "Foo Bar #{id}" }
    email  { "#{name.gsub(' ', '').downcase}@example.com" }
    last_seen_at { Time.now }
    is_active { true }


    factory :admin_user do
      role 'admin'
    end

    factory :limited_admin_user do
      role 'limited_admin'
    end
  end
end
