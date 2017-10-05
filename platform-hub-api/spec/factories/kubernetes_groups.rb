FactoryGirl.define do
  factory :kubernetes_group do
    id { SecureRandom.uuid }
    sequence :name do |n|
      "kube-group:#{n}"
    end
    kind { 'namespace' }
    target { 'user' }
    description { 'This is a kube group' }
  end
end
