require 'rails_helper'

RSpec.describe HelpController, type: :routing do
  describe 'routing' do

    context 'with help_search feature flag enabled' do

      before do
        FeatureFlagService.create_or_update(:help_search, true)
      end

      it 'routes to #search' do
        expect(:get => '/help/search').to route_to('help#search')
      end

      it 'routes to #search_query_stats' do
        expect(:get => '/help/search_query_stats').to route_to('help#search_query_stats')
      end

    end
  end

  context 'with help_search feature flag disabled' do

    before do
      FeatureFlagService.create_or_update(:help_search, false)
    end

    it 'route to #search is not routable' do
      expect(:get => '/help/search').to_not be_routable
    end

    it 'route to #search_query_stats is not routable' do
      expect(:get => '/help/search_query_stats').to_not be_routable
    end

  end

end
