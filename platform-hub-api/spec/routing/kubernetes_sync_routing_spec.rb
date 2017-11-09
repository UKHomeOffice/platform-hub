require 'rails_helper'

RSpec.describe Kubernetes::SyncController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens_sync and kubernetes_tokens feature flags enabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens_sync, true)
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #sync' do
        expect(:post => '/kubernetes/sync').to route_to('kubernetes/sync#sync')
      end
    end

    context 'with kubernetes_tokens_sync feature flag disabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens_sync, false)
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'route to #sync is not routable' do
        expect(:post => '/kubernetes/sync').to_not be_routable
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens_sync, true)
        FeatureFlagService.create_or_update(:kubernetes_tokens, false)
      end

      it 'route to #sync is not routable' do
        expect(:post => '/kubernetes/sync').to_not be_routable
      end
    end

  end
end
