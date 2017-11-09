require 'rails_helper'

RSpec.describe Kubernetes::TokensController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #index' do
        expect(:get => '/kubernetes/tokens').to route_to('kubernetes/tokens#index')
      end

      it 'routes to #create via POST' do
        expect(:post => '/kubernetes/tokens').to route_to('kubernetes/tokens#create')
      end

      it 'routes to #update via PATCH' do
        expect(:patch => '/kubernetes/tokens/1').to route_to('kubernetes/tokens#update', :id => '1')
      end

      it 'routes to #update via PUT' do
        expect(:put => '/kubernetes/tokens/1').to route_to('kubernetes/tokens#update', :id => '1')
      end

      it 'routes to #destroy' do
        expect(:delete => '/kubernetes/tokens/1').to route_to('kubernetes/tokens#destroy', :id => '1')
      end

      it 'routes to #escalate' do
        expect(:patch => '/kubernetes/tokens/1/escalate').to route_to('kubernetes/tokens#escalate', :id => '1')
      end

      it 'routes to #deescalate' do
        expect(:patch => '/kubernetes/tokens/1/deescalate').to route_to('kubernetes/tokens#deescalate', :id => '1')
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      it 'route to #index is not routable' do
        expect(:get => '/kubernetes/tokens').to_not be_routable
      end

      it 'route to #create is not routable' do
        expect(:post => '/kubernetes/tokens').to_not be_routable
      end

      it 'route to #update via PATCH is not routable' do
        expect(:patch => '/kubernetes/tokens/1').to_not be_routable
      end

      it 'route to #update via PUT is not routable' do
        expect(:put => '/kubernetes/tokens/1').to_not be_routable
      end

      it 'route to #destroy is not routable' do
        expect(:delete => '/kubernetes/tokens/1').to_not be_routable
      end

      it 'route to #escalate is not routable' do
        expect(:post => '/kubernetes/tokens/1/escalate').to_not be_routable
      end

      it 'route to #deescalate is not routable' do
        expect(:post => '/kubernetes/tokens/1/deescalate').to_not be_routable
      end
    end

  end
end
