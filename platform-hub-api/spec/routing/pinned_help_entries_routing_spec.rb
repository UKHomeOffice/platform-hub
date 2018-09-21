require 'rails_helper'

RSpec.describe PinnedHelpEntriesController, type: :routing do
  describe 'routing' do

    it 'routes to #show' do
      expect(:get => "/pinned_help_entries").to route_to('pinned_help_entries#show')
    end

    it 'routes to #update' do
      expect(:put => "/pinned_help_entries").to route_to('pinned_help_entries#update')
    end

  end
end
