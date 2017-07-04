require 'rails_helper'

RSpec.describe Kubernetes::ClustersController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do
      before do
	FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #index' do
	expect(:get => '/kubernetes/clusters').to route_to('kubernetes/clusters#index')
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      it 'route to #index is not routable' do
	expect(:get => '/kubernetes/clusters').to_not be_routable
      end
    end

  end
end
