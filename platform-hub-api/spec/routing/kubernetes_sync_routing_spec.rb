require 'rails_helper'

RSpec.describe Kubernetes::SyncController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do
      before do
	FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #sync' do
	expect(:post => '/kubernetes/sync').to route_to('kubernetes/sync#sync')
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      it 'route to #sync is not routable' do
	expect(:post => '/kubernetes/sync').to_not be_routable
      end
    end

  end
end
