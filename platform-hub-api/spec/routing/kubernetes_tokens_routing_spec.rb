require 'rails_helper'

RSpec.describe Kubernetes::TokensController, type: :routing do
  describe 'routing' do

    it 'routes to #index' do
      expect(:get => '/kubernetes/tokens/1').to route_to('kubernetes/tokens#index', :user_id => '1')
    end

    it 'routes to #create_or_update via PUT' do
      expect(:put => '/kubernetes/tokens/1/prod').to route_to('kubernetes/tokens#create_or_update', :user_id => '1', :cluster => 'prod')
    end

    it 'routes to #create_or_update via PATCH' do
      expect(:patch => '/kubernetes/tokens/1/prod').to route_to('kubernetes/tokens#create_or_update', :user_id => '1', :cluster => 'prod')
    end

    it 'routes to #destroy' do
      expect(:delete => '/kubernetes/tokens/1/prod').to route_to('kubernetes/tokens#destroy', :user_id => '1', :cluster => 'prod')
    end

    it 'does not route when user ID not specified' do
      expect(:put => '/kubernetes/tokens').not_to be_routable
    end

  end
end
