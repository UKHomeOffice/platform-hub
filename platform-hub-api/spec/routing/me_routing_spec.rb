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

    it 'routes to #global_announcements_mark_all_read' do
      expect(:post => '/me/global_announcements/mark_all_read').to route_to('me#global_announcements_mark_all_read')
    end

  end
end
