FactoryGirl.define do
  factory :kubernetes_namespace do
    service
    sequence(:name) { |n| "#{service.name.parameterize}-namespace-#{n}" }

    after(:build) do |namespace, evaluator|
      if namespace.cluster.blank? && namespace.service.present?
        namespace.cluster = create :kubernetes_cluster, allocate_to: namespace.service.project
      end
    end
  end
end
