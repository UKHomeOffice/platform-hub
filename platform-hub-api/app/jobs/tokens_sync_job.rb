class TokensSyncJob < ApplicationJob
  queue_as :tokens_sync

  def self.is_already_queued
    Delayed::Job.where(queue: :tokens_sync).count > 0
  end

  def perform
    return unless FeatureFlagService.all_enabled?([
      :kubernetes_tokens_sync,
      :kubernetes_tokens
    ])

    KubernetesCluster.names.each do |cluster_name|
      begin
        Kubernetes::TokenSyncService.sync_tokens(cluster_name)

        AuditService.log(
          action: 'sync_kubernetes_tokens',
          data: { background_job: true, cluster: cluster_name },
          comment: "Kubernetes tokens synced to `#{cluster_name}` cluster via background job."
        )
      rescue => e
        Rails.logger.error "Kubernetes tokens sync to `#{cluster_name}` cluster failed - exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("\n")}"
      end
    end
  end
end
