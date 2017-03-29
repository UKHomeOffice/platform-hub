require 'rails_helper'

RSpec.describe AppSettingsController, type: :routing do
  describe 'routing' do

    it 'routes to #show' do
      expect(:get => '/app_settings').to route_to('app_settings#show')
    end

    it 'routes to #update via PUT' do
      expect(:put => '/app_settings').to route_to('app_settings#update')
    end

    it 'routes to #update via PATCH' do
      expect(:patch => '/app_settings').to route_to('app_settings#update')
    end

  end
end
