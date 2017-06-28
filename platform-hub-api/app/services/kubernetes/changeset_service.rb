module Kubernetes
  module ChangesetService
    extend self

    CHANGSET_ACTIONS = [
      :update_kubernetes_identity,
      :revoke_kubernetes_token,
      :claim_kubernetes_token,
    ]

    def get_events(cluster, since)
      audit_entities(CHANGSET_ACTIONS, cluster).where("created_at > ?", since)
    end

    def last_sync(cluster)
      audit_entities(:sync_kubernetes_tokens, cluster).first.try(:created_at) || 1.year.ago.utc.to_s(:db)
    end

    private

    def audit_entities(actions, cluster)
      Audit.by_action(actions).where("data->>'cluster' = ?", cluster).order(id: :desc)
    end

  end
end
