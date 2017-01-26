require 'rails_helper'

RSpec.describe ProjectsController, type: :routing do
  describe 'routing' do

    it 'routes to #index' do
      expect(:get => '/projects').to route_to('projects#index')
    end

    it 'routes to #show' do
      expect(:get => '/projects/1').to route_to('projects#show', :id => '1')
    end

    it 'routes to #create' do
      expect(:post => '/projects').to route_to('projects#create')
    end

    it 'routes to #update via PUT' do
      expect(:put => '/projects/1').to route_to('projects#update', :id => '1')
    end

    it 'routes to #update via PATCH' do
      expect(:patch => '/projects/1').to route_to('projects#update', :id => '1')
    end

    it 'routes to #destroy' do
      expect(:delete => '/projects/1').to route_to('projects#destroy', :id => '1')
    end

    it 'routes to #memberships' do
      expect(:get => '/projects/1/memberships').to route_to('projects#memberships', :id => '1')
    end

    it 'routes to #add_membership' do
      expect(:put => '/projects/1/memberships/25').to route_to('projects#add_membership', :id => '1', :user_id => '25')
    end

    it 'routes to #remove_membership' do
      expect(:delete => '/projects/1/memberships/25').to route_to('projects#remove_membership', :id => '1', :user_id => '25')
    end

  end
end
