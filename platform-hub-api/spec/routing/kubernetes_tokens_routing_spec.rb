require 'rails_helper'

RSpec.describe Kubernetes::TokensController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #index' do
        expect(:get => '/kubernetes/tokens/1').to route_to('kubernetes/tokens#index', :user_id => '1')
      end

      it 'routes to #create_or_update via PUT' do
        expect(:put => '/kubernetes/tokens/1/prod').to route_to('kubernetes/tokens#create_or_update', :user_id => '1', :cluster => 'prod')
      end

      it 'routes to #create_or_update via PATCH' do
        expect(:patch => '/kubernetes/tokens/1/prod').to route_to('kubernetes/tokens#create_or_update', :user_id => '1', :cluster => 'prod')
      end

      it 'routes to #destroy' do
        expect(:delete => '/kubernetes/tokens/1/prod').to route_to('kubernetes/tokens#destroy', :user_id => '1', :cluster => 'prod')
      end

      it 'does not route when user ID not specified' do
        expect(:put => '/kubernetes/tokens').not_to be_routable
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      it 'route to #index is not routable' do
        expect(:get => '/kubernetes/tokens/1').to_not be_routable
      end

      it 'route to #create_or_update via PUT is not routable' do
        expect(:put => '/kubernetes/tokens/1/prod').to_not be_routable
      end

      it 'route to #create_or_update via PATCH is not routable' do
        expect(:patch => '/kubernetes/tokens/1/prod').to_not be_routable
      end

      it 'route to #destroy is not routable' do
        expect(:delete => '/kubernetes/tokens/1/prod').to_not be_routable
      end
    end

  end
end
