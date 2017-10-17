FactoryGirl.define do
  factory :kubernetes_token do

    association :cluster, factory: :kubernetes_cluster
    token { SecureRandom.uuid }
    uid { SecureRandom.uuid }
    groups { ['group1', 'group2'] }
    expire_privileged_at { nil }

    factory :user_kubernetes_token do
      kind { 'user' }
      association :tokenable, factory: :kubernetes_identity
      name { "user_#{SecureRandom.uuid}@example.com" }

      factory :privileged_kubernetes_token do
        groups { ['privileged'] }
        expire_privileged_at { 3600.seconds.from_now }
      end
    end

    factory :robot_kubernetes_token do
      kind { 'robot' }
      association :tokenable, factory: :user
      name { "some_robot" }
      description { "Awesome Robot" }
    end
  end
end
