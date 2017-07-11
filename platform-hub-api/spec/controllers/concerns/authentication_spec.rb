require 'rails_helper'

describe 'Authentication Concern', type: :controller do
  controller do
    include Authentication

    before_action :require_authentication

    def index
      head :no_content
    end
  end

  before do
    expect(@controller).to receive(:authenticated?).and_call_original
  end

  context 'with no authentication token provided' do
    let(:auth_token) do
      nil
    end

    before do
      expect(@controller).to receive(:current_user).and_call_original
      expect(@controller).to receive(:token_and_options).and_return([auth_token, nil])
    end

    it 'should check for a current user and then return a 401 Unauthorized' do
      expect(AuthUserService).not_to receive(:get)

      get :index
      expect(response).to have_http_status(401)
    end
  end

  context 'with authentication token provided' do
    let(:auth_token) do
      test_auth_token
    end

    before do
      expect(@controller).to receive(:current_user).twice.and_call_original
      expect(@controller).to receive(:token_and_options).twice.and_return([auth_token, nil])
    end

    context 'when user is active' do
      let(:user) { build(:user) }

      it 'should check for a current user and create one' do
        expect(AuthUserService).to receive(:get).and_return(user)
        expect(AuthUserService).to receive(:touch_and_update_main_identity).with(user, test_auth_payload)

        get :index
        expect(response).to have_http_status(204)
      end
    end

    context 'when user is not active' do
      let(:user) { build(:user, is_active: false) }

      it 'should return 418 (I Am A Teapot)' do
        expect(AuthUserService).to receive(:get).and_return(user)
        expect(AuthUserService).to receive(:touch_and_update_main_identity).with(user, test_auth_payload)

        get :index
        expect(response).to have_http_status(418)
      end
    end
  end

end
