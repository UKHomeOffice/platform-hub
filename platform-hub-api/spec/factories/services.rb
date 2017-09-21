FactoryGirl.define do
  factory :service do
    id { SecureRandom.uuid }
    sequence :name do |n|
      "Service #{n}"
    end
    sequence :description do |n|
      "Service description #{n}"
    end
    project
  end
end
