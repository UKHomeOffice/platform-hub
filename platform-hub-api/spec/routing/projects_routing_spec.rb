require 'rails_helper'

RSpec.describe ProjectsController, type: :routing do
  describe 'routing' do

    context 'with projects feature flag enabled' do

      before do
        FeatureFlagService.create_or_update(:projects, true)
      end

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

      it 'routes to #role_check' do
        expect(:get => '/projects/1/memberships/role_check/manager').to route_to('projects#role_check', :id => '1', :role => 'manager')
      end

      it 'routes to #set_role' do
        expect(:put => '/projects/1/memberships/25/role/manager').to route_to('projects#set_role', :id => '1', :user_id => '25', :role => 'manager')
      end

      it 'routes to #unset_role' do
        expect(:delete => '/projects/1/memberships/25/role/manager').to route_to('projects#unset_role', :id => '1', :user_id => '25', :role => 'manager')
      end

      it 'does not route when given an unidentified "role"' do
        expect(:put => '/projects/1/memberships/25/role/unknown_role').not_to be_routable
      end

    end

    context 'with projects feature flag disabled' do

      before do
        FeatureFlagService.create_or_update(:projects, false)
      end

      it 'route to #index is not routable' do
        expect(:get => '/projects').to_not be_routable
      end

      it 'route to #show is not routable' do
        expect(:get => '/projects/1').to_not be_routable
      end

      it 'route to #create is not routable' do
        expect(:post => '/projects').to_not be_routable
      end

      it 'route to #update via PUT is not routable' do
        expect(:put => '/projects/1').to_not be_routable
      end

      it 'route to #update via PATCH is not routable' do
        expect(:patch => '/projects/1').to_not be_routable
      end

      it 'route to #destroy is not routable' do
        expect(:delete => '/projects/1').to_not be_routable
      end

      it 'route to #memberships is not routable' do
        expect(:get => '/projects/1/memberships').to_not be_routable
      end

      it 'route to #add_membership is not routable' do
        expect(:put => '/projects/1/memberships/25').to_not be_routable
      end

      it 'route to #remove_membership is not routable' do
        expect(:delete => '/projects/1/memberships/25').to_not be_routable
      end

      it 'route to #role_check is not routable' do
        expect(:get => '/projects/1/memberships/role_check/manager').to_not be_routable
      end

      it 'route to #set_role is not routable' do
        expect(:put => '/projects/1/memberships/25/role/manager').to_not be_routable
      end

      it 'route to #unset_role is not routable' do
        expect(:delete => '/projects/1/memberships/25/role/manager').to_not be_routable
      end

    end

  end
end
