require 'rails_helper'

RSpec.describe Kubernetes::ClaimController, type: :routing do
  describe 'routing' do

    it 'routes to #claim' do
      expect(:post => '/kubernetes/claim').to route_to('kubernetes/claim#claim')
    end

  end
end
