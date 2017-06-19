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
    expect(@controller).to receive(:current_user).and_call_original
    expect(@controller).to receive(:token_and_options).and_return([auth_token, nil])
  end

  context 'with no authentication token provided' do
    let(:auth_token) do
      nil
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

    it 'should check for a current user and create one' do
      user = instance_double('User')

      expect(AuthUserService).to receive(:get).and_return(user)
      expect(user).to receive(:touch).with(:last_seen_at)

      get :index
      expect(response).to have_http_status(204)
    end
  end

end
