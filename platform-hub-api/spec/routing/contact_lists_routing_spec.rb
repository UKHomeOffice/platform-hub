require 'rails_helper'

RSpec.describe ContactListsController, type: :routing do
  describe 'routing' do

    it 'doesn\'t route an invalid ID' do
      expect(:get => '/contact_lists/_foo').not_to be_routable
      expect(:get => '/contact_lists/foo$').not_to be_routable
      expect(:get => '/contact_lists/foo-bar').not_to be_routable
    end

    it 'routes to #show' do
      expect(:get => '/contact_lists/foo').to route_to('contact_lists#show', id: 'foo')
    end

    it 'routes to #update via PUT' do
      expect(:put => '/contact_lists/foo').to route_to('contact_lists#update', id: 'foo')
    end

    it 'routes to #update via PATCH' do
      expect(:patch => '/contact_lists/foo').to route_to('contact_lists#update', id: 'foo')
    end

  end
end
