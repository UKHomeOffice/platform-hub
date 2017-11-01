FactoryGirl.define do
  factory :kubernetes_token do

    token { SecureRandom.uuid }
    uid { SecureRandom.uuid }
    expire_privileged_at { nil }

    factory :user_kubernetes_token do
      kind { 'user' }
      association :cluster, factory: :kubernetes_cluster
      association :project
      association :tokenable, factory: :kubernetes_identity
      name { "user_#{SecureRandom.uuid}@example.com" }

      groups do
        [
          create(:kubernetes_group, :not_privileged, :for_user).name,
          create(:kubernetes_group, :not_privileged, :for_user).name
        ]
      end

      factory :privileged_kubernetes_token do
        groups { create(:kubernetes_group, :privileged, :for_user).name }
        expire_privileged_at { 3600.seconds.from_now }
      end
    end

    factory :robot_kubernetes_token do
      kind { 'robot' }
      association :tokenable, factory: :service
      sequence :name do |n|
        "mr_robot_#{n}"
      end
      description { "Mr Robot" }

      transient do
        groups_count 2
      end

      after(:build) do |token, evaluator|
        if token.cluster.blank? && token.tokenable.present? && token.tokenable.is_a?(Service)
          token.cluster = create :kubernetes_cluster, allocate_to: token.tokenable.project
        end

        if token.groups.nil? && !evaluator.groups_count.zero?
          token.groups = evaluator.groups_count.map do |i|
            create :kubernetes_group, :not_privileged, :for_robot, allocate_to: token.tokenable
          end
        end
      end
    end
  end
end
