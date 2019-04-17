require 'rails_helper'

RSpec.describe SupportRequestsController, type: :routing do
  describe 'routing' do

    context 'with support_requests feature flag enabled' do

      before do
        FeatureFlagService.create_or_update(:support_requests, true)
      end

      it 'routes to #create' do
        expect(:post => '/support_requests').to route_to('support_requests#create')
      end

    end

    context 'with support_requests feature flag disabled' do

      before do
        FeatureFlagService.create_or_update(:support_requests, false)
      end

      it 'route to #create is not routable' do
        expect(:post => '/support_requests').to_not be_routable
      end

    end

  end
end
