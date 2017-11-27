require "rails_helper"

RSpec.describe Kubernetes::NamespacesController, type: :routing do
  describe "routing" do

    context 'with kubernetes_tokens feature flag enabled' do

      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #index' do
        expect(:get => '/kubernetes/namespaces').to route_to('kubernetes/namespaces#index')
      end

      it 'routes to #show' do
        expect(:get => '/kubernetes/namespaces/1').to route_to('kubernetes/namespaces#show', :id => '1')
      end

      it 'routes to #create' do
        expect(:post => '/kubernetes/namespaces').to route_to('kubernetes/namespaces#create')
      end

      it 'routes to #update via PUT' do
        expect(:put => '/kubernetes/namespaces/1').to route_to('kubernetes/namespaces#update', :id => '1')
      end

      it 'routes to #update via PATCH' do
        expect(:patch => '/kubernetes/namespaces/1').to route_to('kubernetes/namespaces#update', :id => '1')
      end

      it 'routes to #destroy' do
        expect(:delete => '/kubernetes/namespaces/1').to route_to('kubernetes/namespaces#destroy', :id => '1')
      end

    end

    context 'with kubernetes_tokens feature flag disabled' do

      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, false)
      end

      it 'route to #index is not routable' do
        expect(:get => '/kubernetes/namespaces').to_not be_routable
      end

      it 'route to #show is not routable' do
        expect(:get => '/kubernetes/namespaces/1').to_not be_routable
      end

      it 'route to #create is not routable' do
        expect(:post => '/kubernetes/namespaces').to_not be_routable
      end

      it 'route to #update via PUT is not routable' do
        expect(:put => '/kubernetes/namespaces/1').to_not be_routable
      end

      it 'route to #update via PATCH is not routable' do
        expect(:patch => '/kubernetes/namespaces/1').to_not be_routable
      end

      it 'route to #destroy is not routable' do
        expect(:delete => '/kubernetes/namespaces/1').to_not be_routable
      end

    end

  end
end
