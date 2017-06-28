require 'rails_helper'

RSpec.describe Kubernetes::ClaimController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do
      before do
	FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #claim' do
	expect(:post => '/kubernetes/claim').to route_to('kubernetes/claim#claim')
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      it 'route to #claim is not routable' do
	expect(:post => '/kubernetes/claim').to_not be_routable
      end
    end


  end
end
