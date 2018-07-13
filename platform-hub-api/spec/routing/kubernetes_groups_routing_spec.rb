require 'rails_helper'

RSpec.describe Kubernetes::GroupsController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do

      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #index' do
        expect(:get => '/kubernetes/groups').to route_to('kubernetes/groups#index')
      end

      it 'routes to #show' do
        expect(:get => '/kubernetes/groups/1').to route_to('kubernetes/groups#show', :id => '1')
      end

      it 'routes to #create' do
        expect(:post => '/kubernetes/groups').to route_to('kubernetes/groups#create')
      end

      it 'routes to #update via PUT' do
        expect(:put => '/kubernetes/groups/1').to route_to('kubernetes/groups#update', :id => '1')
      end

      it 'routes to #update via PATCH' do
        expect(:patch => '/kubernetes/groups/1').to route_to('kubernetes/groups#update', :id => '1')
      end

      it 'routes to #destroy' do
        expect(:delete => '/kubernetes/groups/1').to route_to('kubernetes/groups#destroy', :id => '1')
      end

      it 'routes to #allocate' do
        expect(:post => '/kubernetes/groups/1/allocate').to route_to('kubernetes/groups#allocate', :id => '1')
      end

      it 'routes to #allocations' do
        expect(:get => '/kubernetes/groups/1/allocations').to route_to('kubernetes/groups#allocations', :id => '1')
      end

      it 'routes to #tokens' do
        expect(:get => '/kubernetes/groups/1/tokens').to route_to('kubernetes/groups#tokens', :id => '1')
      end

      it 'routes to #filters' do
        expect(:get => '/kubernetes/groups/filters').to route_to('kubernetes/groups#filters')
      end

    end

    context 'with kubernetes_tokens feature flag disabled' do

      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, false)
      end

      it 'route to #index is not routable' do
        expect(:get => '/kubernetes/groups').to_not be_routable
      end

      it 'route to #show is not routable' do
        expect(:get => '/kubernetes/groups/1').to_not be_routable
      end

      it 'route to #create is not routable' do
        expect(:post => '/kubernetes/groups').to_not be_routable
      end

      it 'route to #update via PUT is not routable' do
        expect(:put => '/kubernetes/groups/1').to_not be_routable
      end

      it 'route to #update via PATCH is not routable' do
        expect(:patch => '/kubernetes/groups/1').to_not be_routable
      end

      it 'route to #destroy is not routable' do
        expect(:delete => '/kubernetes/groups/1').to_not be_routable
      end

      it 'route to #allocate is not routable' do
        expect(:post => '/kubernetes/groups/1/allocate').to_not be_routable
      end

      it 'route to #allocations is not routable' do
        expect(:get => '/kubernetes/groups/1/allocations').to_not be_routable
      end

      it 'route to #tokens is not routable' do
        expect(:get => '/kubernetes/groups/1/tokens').to_not be_routable
      end

      it 'route to #filters is not routable' do
        expect(:get => '/kubernetes/groups/filters').to_not be_routable
      end

    end

  end
end
