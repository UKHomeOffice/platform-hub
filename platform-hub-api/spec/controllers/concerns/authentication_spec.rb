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
      expect(User).not_to receive(:find_by_id)
      expect(NewUserService).not_to receive(:new)

      get :index
      expect(response).to have_http_status(401)
    end
  end

  context 'with authentication token provided' do
    let(:auth_token) do
      test_auth_token
    end

    it 'should check for a current user and create one' do
      new_user_service = double
      user = double

      expect(User).to receive(:find_by_id).with(test_auth_payload.sub).and_call_original
      expect(NewUserService).to receive(:new).and_return(new_user_service)
      expect(new_user_service).to receive(:create).with(test_auth_payload).and_return(user)

      get :index
      expect(response).to have_http_status(204)
    end
  end

end
