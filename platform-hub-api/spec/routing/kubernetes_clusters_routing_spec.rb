require 'rails_helper'

RSpec.describe Kubernetes::ClustersController, type: :routing do
  describe 'routing' do

    it 'routes to #index' do
      expect(:get => '/kubernetes/clusters').to route_to('kubernetes/clusters#index')
    end

  end
end
