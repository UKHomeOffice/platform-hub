FactoryGirl.define do
  factory :docs_source do
    id { SecureRandom.uuid }

    kind :github_repo

    sequence :name do |n|
      "Source #{n}"
    end

    config { {} }
  end
end
