require 'rails_helper'

RSpec.describe IdentityFlowsController, type: :controller do

  describe "GET #start_auth_flow" do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :start_auth_flow, params: { service: 'github' }
      end
    end
  end

  describe "GET #callback" do
    it 'should allow unauthenticated access but cannot process the request due to a missing param' do
      get :callback, params: { service: 'github' }
      expect(response).to have_http_status(422)
    end
  end

end
