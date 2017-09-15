require 'rails_helper'

RSpec.describe Kubernetes::GroupsController, type: :routing do
  describe 'routing' do

    context 'with kubernetes_tokens feature flag enabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #privileged' do
        expect(:get => '/kubernetes/groups/privileged').to route_to('kubernetes/groups#privileged')
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      it 'route to #privileged is not routable' do
        expect(:get => '/kubernetes/groups/privileged').to_not be_routable
      end
    end

  end
end
