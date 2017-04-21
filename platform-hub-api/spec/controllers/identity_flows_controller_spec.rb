require 'rails_helper'

RSpec.describe IdentityFlowsController, type: :controller do

  describe 'GET #start_auth_flow' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :start_auth_flow, params: { service: 'github' }
      end
    end
  end

  describe 'GET #callback' do
    it 'should allow unauthenticated access but handle a missing "code" param' do
      get :callback, params: { service: 'github' }
      expect(response).to have_http_status(422)
    end

    it 'should allow unauthenticated access but handle a missing "state" param' do
      get :callback, params: { service: 'github', code: 'foo' }
      expect(response).to have_http_status(422)
    end

    context 'the GitHubIdentityService throws a NoAccessToken error' do
      let(:code) { 'code' }

      let(:state) { 'state' }

      let :git_hub_identity_service do
        instance_double('GitHubIdentityService')
      end

      before do
        expect(controller).to receive(:git_hub_identity_service).and_return(git_hub_identity_service)
        expect(git_hub_identity_service).to receive(:connect_identity).with(code, state).and_raise(GitHubIdentityService::Errors::NoAccessToken)
      end

      it 'should handle the error and respond with an HTTP 403' do
        get :callback, params: { service: 'github', code: code, state: state }
        expect(response).to have_http_status(403)
      end
    end
  end

end
