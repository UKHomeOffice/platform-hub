require 'rails_helper'

RSpec.describe AnnouncementsController, type: :routing do
  describe 'routing' do

    it 'routes to #index' do
      expect(:get => '/announcements').to route_to('announcements#index')
    end

    it 'routes to #global' do
      expect(:get => '/announcements/global').to route_to('announcements#global')
    end

    it 'routes to #show' do
      expect(:get => '/announcements/1').to route_to('announcements#show', :id => '1')
    end

    it 'routes to #create' do
      expect(:post => '/announcements').to route_to('announcements#create')
    end

    it 'routes to #update via PUT' do
      expect(:put => '/announcements/1').to route_to('announcements#update', :id => '1')
    end

    it 'routes to #update via PATCH' do
      expect(:patch => '/announcements/1').to route_to('announcements#update', :id => '1')
    end

    it 'routes to #destroy' do
      expect(:delete => '/announcements/1').to route_to('announcements#destroy', :id => '1')
    end

    it 'routes to #mark_sticky' do
      expect(:post => '/announcements/1/mark_sticky').to route_to('announcements#mark_sticky', :id => '1')
    end

    it 'routes to #unmark_sticky' do
      expect(:post => '/announcements/1/unmark_sticky').to route_to('announcements#unmark_sticky', :id => '1')
    end

  end
end
