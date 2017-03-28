require 'rails_helper'

RSpec.describe PlatformThemesController, type: :routing do
  describe 'routing' do

    it 'routes to #index' do
      expect(:get => '/platform_themes').to route_to('platform_themes#index')
    end

    it 'routes to #show' do
      expect(:get => '/platform_themes/1').to route_to('platform_themes#show', :id => '1')
    end

    it 'routes to #create' do
      expect(:post => '/platform_themes').to route_to('platform_themes#create')
    end

    it 'routes to #update via PUT' do
      expect(:put => '/platform_themes/1').to route_to('platform_themes#update', :id => '1')
    end

    it 'routes to #update via PATCH' do
      expect(:patch => '/platform_themes/1').to route_to('platform_themes#update', :id => '1')
    end

    it 'routes to #destroy' do
      expect(:delete => '/platform_themes/1').to route_to('platform_themes#destroy', :id => '1')
    end

  end
end
