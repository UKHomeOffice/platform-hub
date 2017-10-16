require 'rails_helper'

RSpec.describe AllocationsController, type: :routing do
  describe 'routing' do

    it 'routes to #destroy' do
      expect(:delete => '/allocations/1').to route_to('allocations#destroy', :id => '1')
    end

  end
end
