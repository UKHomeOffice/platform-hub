require 'rails_helper'

RSpec.describe Kubernetes::RevokeController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do
      before do
	FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #revoke' do
	expect(:post => '/kubernetes/revoke').to route_to('kubernetes/revoke#revoke')
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      it 'route to #revoke is not routable' do
	expect(:post => '/kubernetes/revoke').to_not be_routable
      end
    end

  end
end
