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

    it 'routes to #complete_hub_onboarding' do
      expect(:post => '/me/complete_hub_onboarding').to route_to('me#complete_hub_onboarding')
    end

  end
end
