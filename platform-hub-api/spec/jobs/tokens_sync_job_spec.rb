require 'rails_helper'

RSpec.describe TokensSyncJob, type: :job do

  describe '.is_already_queued?' do
    it 'should recognise when the job is already queued' do
      expect(TokensSyncJob.is_already_queued?).to be false

      TokensSyncJob.perform_later

      expect(TokensSyncJob.is_already_queued?).to be true
    end
  end

  describe '.perform' do

    context 'with kubernetes_tokens_sync and kubernetes_tokens feature flags enabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens_sync, true)
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      let!(:syncable_clusters) do
        create_list :kubernetes_cluster, 2, skip_sync: false
      end

      let!(:not_syncable_clusters) do
        create_list :kubernetes_cluster, 2, skip_sync: true
      end

      before do
        syncable_clusters.map(&:name).each do |cluster_name|
          expect(Kubernetes::TokenSyncService).to receive(:sync_tokens).with(cluster_name)

          expect(AuditService).to receive(:log).with(
            action: 'sync_kubernetes_tokens',
            data: { background_job: true, cluster: cluster_name },
            comment: "Kubernetes tokens synced to `#{cluster_name}` cluster via background job."
          )
        end

        not_syncable_clusters.map(&:name).each do |cluster_name|
          expect(Kubernetes::TokenSyncService).not_to receive(:sync_tokens)

          expect(AuditService).not_to receive(:log)
        end
      end

      it 'should call the token sync service for just the syncable clusters and register appropriate audits' do
        TokensSyncJob.new.perform
      end
    end

    context 'with kubernetes_tokens_sync feature flag disabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens_sync, false)
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'should not do anything' do
        expect(KubernetesCluster).to receive(:names).never
        expect(Kubernetes::TokenSyncService).to receive(:sync_tokens).never
        expect(AuditService).to receive(:log).never
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens_sync, true)
        FeatureFlagService.create_or_update(:kubernetes_tokens, false)
      end

      it 'should not do anything' do
        expect(KubernetesCluster).to receive(:names).never
        expect(Kubernetes::TokenSyncService).to receive(:sync_tokens).never
        expect(AuditService).to receive(:log).never
      end
    end

  end

end
