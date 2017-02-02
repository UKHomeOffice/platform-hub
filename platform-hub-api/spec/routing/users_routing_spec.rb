require 'rails_helper'

RSpec.describe UsersController, type: :routing do
  describe 'routing' do

    it 'routes to #index' do
      expect(:get => '/users').to route_to('users#index')
    end

    it 'routes to #show' do
      expect(:get => '/users/1').to route_to('users#show', :id => '1')
    end

    it 'routes to #search' do
      expect(:get => '/users/search/foo').to route_to('users#search', :q => 'foo')
    end

    it 'routes to #make_admin' do
      expect(:post => '/users/1/make_admin').to route_to('users#make_admin', :id => '1')
    end

    it 'routes to #revoke_admin' do
      expect(:post => '/users/1/revoke_admin').to route_to('users#revoke_admin', :id => '1')
    end

  end
end
