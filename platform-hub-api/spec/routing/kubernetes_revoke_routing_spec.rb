require 'rails_helper'

RSpec.describe Kubernetes::RevokeController, type: :routing do
  describe 'routing' do

    it 'routes to #revoke' do
      expect(:post => '/kubernetes/revoke').to route_to('kubernetes/revoke#revoke')
    end

  end
end
