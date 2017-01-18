require 'rails_helper'

RSpec.describe MeController, type: :controller do

  describe "GET #show" do
    it_behaves_like 'not authenticated' do
      before do
        get :show
      end
    end

    it_behaves_like 'authenticated' do
      it "should return information about the currently authenticated user" do
        get :show
        expect(response).to be_success
        expect(json_response).to eq({
          'id' => test_auth_payload.sub,
          'name' => test_auth_payload.name,
          'email' => test_auth_payload.email
        })
      end
    end
  end

end
