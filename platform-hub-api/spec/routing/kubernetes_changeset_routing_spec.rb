require 'rails_helper'

RSpec.describe Kubernetes::ChangesetController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #index' do
        expect(:get => '/kubernetes/changeset/development').to route_to('kubernetes/changeset#index', :cluster => 'development')
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      it 'route to #index is not routable' do
        expect(:get => '/kubernetes/changeset/development').to_not be_routable
      end
    end

  end
end
