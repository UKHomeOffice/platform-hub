FactoryBot.define do
  factory :kubernetes_group do
    id { SecureRandom.uuid }
    sequence :name do |n|
      "kube-group:#{n}"
    end
    kind { 'namespace' }
    target { 'user' }
    description { 'This is a kube group' }
    is_privileged { false }

    trait :not_privileged do
      is_privileged { false }
    end

    trait :privileged do
      is_privileged { true }
    end

    trait :for_namespace do
      kind { 'namespace' }
    end

    trait :for_clusterwide do
      kind { 'clusterwide' }
    end

    trait :for_user do
      target { 'user' }
    end

    trait :for_robot do
      target { 'robot' }
    end

    transient do
      allocate_to { nil }
    end

    after(:create) do |group, evaluator|
      unless evaluator.allocate_to.blank?
        Array(evaluator.allocate_to).each do |ar|
          raise ArgumentError, '[factory create error] allocate_to must be a Project or a Service' unless ar.is_a?(Project) || ar.is_a?(Service)
          unless Allocation.exists?(allocatable: group, allocation_receivable: ar)
            create :allocation, allocatable: group, allocation_receivable: ar
          end
        end
      end
    end
  end
end
