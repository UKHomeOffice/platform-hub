require 'rails_helper'

RSpec.describe Kubernetes::SyncController, type: :routing do
  describe 'routing' do

    it 'routes to #sync' do
      expect(:post => '/kubernetes/sync').to route_to('kubernetes/sync#sync')
    end

  end
end
