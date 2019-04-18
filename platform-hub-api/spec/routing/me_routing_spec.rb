require 'rails_helper'

RSpec.describe MeController, type: :routing do
  describe 'routing' do

    it 'routes to #show' do
      expect(:get => '/me').to route_to('me#show')
    end

    describe '#delete_identity' do
      it 'should route as expected for an allowed service' do
        expect(:delete => '/me/identities/github').to route_to(
          :controller => 'me',
          :action => 'delete_identity',
          :service => 'github'
        )
      end

      it 'should not route an unknown/unallowed service' do
        expect(:delete => '/me/identities/no_good_service').not_to be_routable
      end
    end

    it 'routes to #agree_terms_of_service' do
      expect(:post => '/me/agree_terms_of_service').to route_to('me#agree_terms_of_service')
    end

    it 'routes to #complete_hub_onboarding' do
      expect(:post => '/me/complete_hub_onboarding').to route_to('me#complete_hub_onboarding')
    end

    it 'routes to #complete_services_onboarding' do
      expect(:post => '/me/complete_services_onboarding').to route_to('me#complete_services_onboarding')
    end

    context 'with announcements feature flag enabled' do
      before do
        FeatureFlagService.create_or_update(:announcements, true)
      end

      it 'routes to #global_announcements_mark_all_read' do
        expect(:post => '/me/global_announcements/mark_all_read').to route_to('me#global_announcements_mark_all_read')
      end
    end

    context 'with announcements feature flag disabled' do
      before do
        FeatureFlagService.create_or_update(:announcements, false)
      end

      it 'route to #global_announcements_mark_all_read is not routable' do
        expect(:post => '/me/global_announcements/mark_all_read').to_not be_routable
      end
    end

    context 'with kubernetes_tokens feature flag enabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, true)
      end

      it 'routes to #kubernetes_tokens' do
        expect(:get => '/me/kubernetes_tokens').to route_to('me#kubernetes_tokens')
      end
    end

    context 'with kubernetes_tokens feature flag disabled' do
      before do
        FeatureFlagService.create_or_update(:kubernetes_tokens, false)
      end

      it 'should not route to #kubernetes_tokens' do
        expect(:get => '/me/kubernetes_tokens').not_to be_routable
      end
    end

  end
end
