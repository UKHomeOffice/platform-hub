require 'rails_helper'

RSpec.describe MeController, type: :controller do

  let(:now) { Time.now }
  let(:now_json_value) { now.utc.iso8601 }

  before do
    Timecop.freeze(now)
  end

  after do
    Timecop.return
  end

  describe "GET #show" do
    it_behaves_like 'unauthenticated not allowed'  do
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
          'email' => test_auth_payload.email,
          'identities' => [
            {
              'provider' => 'keycloak',
              'external_id' => test_auth_payload.sub,
              'external_username' => test_auth_payload.preferred_username,
              'external_name' => test_auth_payload.name,
              'external_email' => test_auth_payload.email,
              'created_at' => now_json_value,
              'updated_at' => now_json_value
            }
          ]
        })
      end
    end
  end

end
