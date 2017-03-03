require 'rails_helper'

RSpec.describe SupportRequestsController, type: :routing do
  describe 'routing' do

    it 'routes to #create' do
      expect(:post => '/support_requests').to route_to('support_requests#create')
    end

  end
end
