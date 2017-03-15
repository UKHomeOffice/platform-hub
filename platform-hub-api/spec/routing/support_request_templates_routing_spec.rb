require 'rails_helper'

RSpec.describe SupportRequestTemplatesController, type: :routing do
  describe 'routing' do

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

  end
end
