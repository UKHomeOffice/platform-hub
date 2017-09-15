class TokensSyncJob < ApplicationJob
  queue_as :tokens_sync

  def self.is_already_queued
    Delayed::Job.where(queue: :tokens_sync).count > 0
  end

  def perform
    return unless FeatureFlagService.is_enabled?(:kubernetes_tokens)

    cluster_ids = Kubernetes::ClusterService.list.map{|c| c['id']}

    cluster_ids.each do |id|
      begin
        Kubernetes::TokenSyncService.sync_tokens(
          cluster: id
        )

        AuditService.log(
          action: 'sync_kubernetes_tokens',
          data: { background_job: true, cluster: id },
          comment: "Kubernetes tokens synced to `#{id}` cluster via background job."
        )
      rescue => e
        Rails.logger.error "Kubernetes tokens sync to `#{id}` cluster failed - exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("\n")}"
      end
    end
  end
end
