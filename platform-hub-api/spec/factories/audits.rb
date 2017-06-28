FactoryGirl.define do
  factory :audit do
    action { 'some_action' }
    auditable { nil }
    associated { nil }
    user { build(:user) }
    user_name { user.name }
    user_email { user.email }
    comment { 'some comment' }
    data { nil }
    remote_ip { '10.10.10.10' }
    request_uuid { SecureRandom.uuid }
    created_at { Time.now }

    factory :sync_kubernetes_tokens_audit do
      action 'sync_kubernetes_tokens'
    end

    factory :update_kubernetes_identity_audit do
      action 'update_kubernetes_identity'
    end

    factory :revoke_kubernetes_token_audit do
      action 'revoke_kubernetes_token'
    end

    factory :claim_kubernetes_token_audit do
      action 'claim_kubernetes_token'
    end
  end
end
