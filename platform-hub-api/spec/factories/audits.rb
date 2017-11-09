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

    # Set by Kubernetes Sync controller
    factory :sync_kubernetes_tokens_audit do
      action :sync_kubernetes_tokens
    end

    # KubernetesToken specific audits
    factory :create_kubernetes_token_audit do
      action :create
    end
    factory :update_kubernetes_token_audit do
      action :update
    end
    factory :destroy_kubernetes_token_audit do
      action :destroy
    end
    factory :escalate_kubernetes_token_audit do
      action :escalate
    end
    factory :deescalate_kubernetes_token_audit do
      action :deescalate
    end

  end
end
