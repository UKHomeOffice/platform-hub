FactoryGirl.define do
  factory :identity do
    provider 'github'
    user
    sequence :external_id do |n|
      "#{provider}_external_id_#{n}"
    end

    factory :github_identity do
    end

    factory :kubernetes_identity do
      provider 'kubernetes'
    end

    factory :ecr_identity do
      provider 'ecr'
      data do
        {
          'credentials' => {
            'access_key' => SecureRandom.uuid,
            'access_secret' => SecureRandom.uuid,
          }
        }
      end
    end
  end
end
