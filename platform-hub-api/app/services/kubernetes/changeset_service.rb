module Kubernetes
  module ChangesetService
    extend self

    AUDITABLE_CHANGESET_ACTIONS = {
      'KubernetesToken' => [
        :create,
        :update,
        :destroy,
        :escalate,
        :deescalate,
      ]
    }

    def get_events(cluster)
      since = last_sync(cluster)

      AUDITABLE_CHANGESET_ACTIONS.collect do |auditable_type, actions|
        audit_entities_by_cluster_and_auditable_type(cluster, auditable_type, actions).where("created_at > ?", since)
      end.flatten
    end

    private

    def last_sync(cluster)
      audit_entities_by_cluster(cluster, :sync_kubernetes_tokens).first.try(:created_at) || 1.year.ago.utc.to_s(:db)
    end

    def audit_entities_by_cluster(cluster, actions)
      Audit.by_action(actions).where("data->>'cluster' = ?", cluster).order(id: :desc)
    end

    def audit_entities_by_cluster_and_auditable_type(cluster, auditable_type, actions)
      Audit.by_auditable_type(auditable_type).by_action(actions).where("data->>'cluster' = ?", cluster).order(id: :desc)
    end

  end
end
