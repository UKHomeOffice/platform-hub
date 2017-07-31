require 'rails_helper'

RSpec.describe FeatureFlagsController, type: :routing do
  describe 'routing' do

    it 'routes to #index' do
      expect(:get => '/feature_flags').to route_to('feature_flags#index')
    end

    it 'routes to #update_flag' do
      expect(:put => '/feature_flags/foo').to route_to('feature_flags#update_flag', :flag => 'foo')
    end

  end
end
