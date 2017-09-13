FactoryGirl.define do
  factory :kubernetes_token do
    identity { build(:kubernetes_identity) }
    cluster { 'development' }
    token { SecureRandom.uuid }
    uid { SecureRandom.uuid }
    groups { ['group1', 'group2'] }

    initialize_with { new(identity: identity, cluster: cluster, token: token, uid: uid, groups: groups) }

    factory :privileged_kubernetes_token do
      expire_privileged_at { 1.hour.from_now }
    end
  end
end
