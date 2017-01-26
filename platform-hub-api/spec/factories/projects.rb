FactoryGirl.define do
  factory :project do
    id { SecureRandom.uuid }
    sequence :shortname do |n|
      "PROJ#{n}"
    end
    sequence :name do |n|
      "Project #{n}"
    end
  end
end
