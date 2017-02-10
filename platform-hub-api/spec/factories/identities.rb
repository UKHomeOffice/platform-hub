FactoryGirl.define do
  factory :identity do
    provider 'github'
    user
    sequence :external_id do |n|
      "github_#{n}"
    end
  end
end
