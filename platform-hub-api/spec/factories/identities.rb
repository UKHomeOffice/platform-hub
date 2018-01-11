FactoryGirl.define do
  factory :identity do
    provider 'github'
    user
    sequence :external_id do |n|
      "github_#{n}"
    end

    factory :github_identity do
    end

    factory :kubernetes_identity do
      provider 'kubernetes'
    end
  end
end
