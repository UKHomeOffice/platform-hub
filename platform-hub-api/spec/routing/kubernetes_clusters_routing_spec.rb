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

      it 'routes to #show' do
        expect(:get => '/kubernetes/clusters/foo').to route_to('kubernetes/clusters#show', :id => 'foo')
      end

      it 'routes to #create via POST' do
        expect(:post => '/kubernetes/clusters').to route_to('kubernetes/clusters#create')
      end

      it 'routes to #update via PATCH' do
        expect(:patch => '/kubernetes/clusters/foo').to route_to('kubernetes/clusters#update', :id => 'foo')
      end

      it 'routes to #update via PUT' do
        expect(:put => '/kubernetes/clusters/foo').to route_to('kubernetes/clusters#update', :id => 'foo')
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      it 'route to #index is not routable' do
        expect(:get => '/kubernetes/clusters').to_not be_routable
      end

      it 'route to #show is not routable' do
        expect(:get => '/kubernetes/clusters/foo').to_not be_routable
      end

      it 'route to #create is not routable' do
        expect(:post => '/kubernetes/clusters').to_not be_routable
      end

      it 'route to #update is not routable via PATCH' do
        expect(:patch => '/kubernetes/clusters/foo').to_not be_routable
      end

      it 'route to #update is not routable via PUT' do
        expect(:put => '/kubernetes/clusters/foo').to_not be_routable
      end
    end

  end
end
