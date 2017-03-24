FactoryGirl.define do
  factory :kubernetes_token do
    identity { build(:kubernetes_identity) }
    cluster { 'development' }
    token { SecureRandom.uuid }
    uid { SecureRandom.uuid }
    groups { ['group1', 'group2'] }
  end
end
