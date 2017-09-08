require 'rails_helper'

RSpec.describe Kubernetes::RobotTokensController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #index' do
        expect(:get => '/kubernetes/robot_tokens/prod').to route_to('kubernetes/robot_tokens#index', :cluster => 'prod')
      end

      it 'routes to #create_or_update via PUT' do
        expect(:put => '/kubernetes/robot_tokens/prod/foo').to route_to('kubernetes/robot_tokens#create_or_update', :cluster => 'prod', :name => 'foo')
      end

      it 'routes to #create_or_update via PATCH' do
        expect(:patch => '/kubernetes/robot_tokens/prod/foo').to route_to('kubernetes/robot_tokens#create_or_update', :cluster => 'prod', :name => 'foo')
      end

      it 'routes to #destroy' do
        expect(:delete => '/kubernetes/robot_tokens/prod/foo').to route_to('kubernetes/robot_tokens#destroy', :cluster => 'prod', :name => 'foo')
      end

      it 'does not route when user ID not specified' do
        expect(:put => '/kubernetes/robot_tokens').not_to be_routable
      end
    end

    context 'with kubernetes_robot_tokens feature flag disabled' do
      it 'route to #index is not routable' do
        expect(:get => '/kubernetes/robot_tokens/prod').to_not be_routable
      end

      it 'route to #create_or_update via PUT is not routable' do
        expect(:put => '/kubernetes/robot_tokens/prod/foo').to_not be_routable
      end

      it 'route to #create_or_update via PATCH is not routable' do
        expect(:patch => '/kubernetes/robot_tokens/prod/foo').to_not be_routable
      end

      it 'route to #destroy is not routable' do
        expect(:delete => '/kubernetes/robot_tokens/prod/foo').to_not be_routable
      end
    end

  end
end
