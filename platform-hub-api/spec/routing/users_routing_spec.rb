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

    it 'routes to #search with special chars' do
      expect(:get => '/users/search/foo.bar@example.com').to route_to('users#search', :q => 'foo.bar@example.com')
    end

    it 'routes to #search with encoded chars' do
      expect(:get => '/users/search/foo.bar%40example.com').to route_to('users#search', :q => 'foo.bar@example.com')
    end

    it 'routes to #identities' do
      expect(:get => '/users/1/identities').to route_to('users#identities', :id => '1')
    end

    it 'routes to #make_admin' do
      expect(:post => '/users/1/make_admin').to route_to('users#make_admin', :id => '1')
    end

    it 'routes to #revoke_admin' do
      expect(:post => '/users/1/revoke_admin').to route_to('users#revoke_admin', :id => '1')
    end

    it 'routes to #make_limited_admin' do
      expect(:post => '/users/1/make_limited_admin').to route_to('users#make_limited_admin', :id => '1')
    end

    it 'routes to #revoke_limited_admin' do
      expect(:post => '/users/1/revoke_limited_admin').to route_to('users#revoke_limited_admin', :id => '1')
    end

    it 'routes to #activate' do
      expect(:post => '/users/1/activate').to route_to('users#activate', :id => '1')
    end

    it 'routes to #deactivate' do
      expect(:post => '/users/1/deactivate').to route_to('users#deactivate', :id => '1')
    end

    it 'routes to #onboard_github' do
      expect(:post => '/users/1/onboard_github').to route_to('users#onboard_github', :id => '1')
    end

    it 'routes to #offboard_github' do
      expect(:post => '/users/1/offboard_github').to route_to('users#offboard_github', :id => '1')
    end

  end
end
