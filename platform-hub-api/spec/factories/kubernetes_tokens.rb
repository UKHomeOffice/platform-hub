FactoryGirl.define do
  factory :kubernetes_token do

    token { SecureRandom.uuid }
    uid { SecureRandom.uuid }
    expire_privileged_at { nil }

    factory :user_kubernetes_token do
      kind { 'user' }
      association :project
      association :tokenable, factory: :kubernetes_identity
      name { "user_#{SecureRandom.uuid}@example.com" }

      transient do
        groups_count 0
      end

      after(:build) do |token, evaluator|
        if token.cluster.blank? && token.project.present?
          token.cluster = create :kubernetes_cluster, allocate_to: token.project
        end

        if token.user? && token.project.present? && token.tokenable.present? && token.tokenable.is_a?(Identity) && !ProjectMembership.exists?(project_id: token.project_id, user_id: token.tokenable.user_id)
          create :project_membership, project: token.project, user: token.tokenable.user
        end

        if token.groups.blank? && !evaluator.groups_count.zero?
          token.groups = create_list(
            :kubernetes_group,
            evaluator.groups_count,
            :not_privileged,
            :for_user,
            allocate_to: token.project
          ).map(&:name)
        end
      end

      trait :with_nil_cluster do
        after(:build) do |token, _|
          token.cluster = nil
        end
      end

      trait :user_is_not_member_of_project do
        after(:build) do |token, _|
          ProjectMembership.where(project_id: token.project_id, user_id: token.tokenable.user_id).delete_all
        end
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
        groups_count 0
      end

      after(:build) do |token, evaluator|
        if token.cluster.blank? && token.tokenable.present? && token.tokenable.is_a?(Service)
          token.cluster = create :kubernetes_cluster, allocate_to: token.tokenable.project
        end

        if token.groups.blank? && !evaluator.groups_count.zero?
          token.groups = create_list(
            :kubernetes_group,
            evaluator.groups_count,
            :not_privileged,
            :for_robot,
            allocate_to: token.project
          ).map(&:name)
        end
      end
    end
  end
end
