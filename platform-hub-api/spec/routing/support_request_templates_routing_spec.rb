require 'rails_helper'

RSpec.describe SupportRequestTemplatesController, type: :routing do
  describe 'routing' do

    context 'with support_requests feature flag enabled' do

      before do
        FeatureFlagService.create_or_update(:support_requests, true)
      end

      it 'routes to #index' do
        expect(:get => '/support_request_templates').to route_to('support_request_templates#index')
      end

      it 'routes to #show' do
        expect(:get => '/support_request_templates/1').to route_to('support_request_templates#show', :id => '1')
      end

      it 'routes to #create' do
        expect(:post => '/support_request_templates').to route_to('support_request_templates#create')
      end

      it 'routes to #update via PUT' do
        expect(:put => '/support_request_templates/1').to route_to('support_request_templates#update', :id => '1')
      end

      it 'routes to #update via PATCH' do
        expect(:patch => '/support_request_templates/1').to route_to('support_request_templates#update', :id => '1')
      end

      it 'routes to #destroy' do
        expect(:delete => '/support_request_templates/1').to route_to('support_request_templates#destroy', :id => '1')
      end

      it 'routes to #form_field_types' do
        expect(:get => '/support_request_templates/form_field_types').to route_to('support_request_templates#form_field_types')
      end

      it 'routes to #git_hub_repos' do
        expect(:get => '/support_request_templates/git_hub_repos').to route_to('support_request_templates#git_hub_repos')
      end

    end

    context 'with support_requests feature flag disabled' do

      before do
        FeatureFlagService.create_or_update(:support_requests, false)
      end

      it 'route to #index is not routable' do
        expect(:get => '/support_request_templates').to_not be_routable
      end

      it 'route to #show is not routable' do
        expect(:get => '/support_request_templates/1').to_not be_routable
      end

      it 'route to #create is not routable' do
        expect(:post => '/support_request_templates').to_not be_routable
      end

      it 'route to #update via PUT is not routable' do
        expect(:put => '/support_request_templates/1').to_not be_routable
      end

      it 'route to #update via PATCH is not routable' do
        expect(:patch => '/support_request_templates/1').to_not be_routable
      end

      it 'route to #destroy is not routable' do
        expect(:delete => '/support_request_templates/1').to_not be_routable
      end

      it 'route to #form_field_types is not routable' do
        expect(:get => '/support_request_templates/form_field_types').to_not be_routable
      end

      it 'route to #git_hub_repos is not routable' do
        expect(:get => '/support_request_templates/git_hub_repos').to_not be_routable
      end

    end

  end
end
