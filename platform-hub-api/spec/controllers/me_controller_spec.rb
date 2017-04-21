require 'rails_helper'

RSpec.describe MeController, type: :controller do

  include_context 'time helpers'

  describe 'GET #show' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show
      end
    end

    it_behaves_like 'authenticated' do
      it 'should return information about the currently authenticated user' do
        get :show
        expect(response).to be_success
        expect(json_response).to eq({
          'id' => test_auth_payload.sub,
          'name' => test_auth_payload.name,
          'email' => test_auth_payload.email,
          'role' => nil,
          'last_seen_at' => now_json_value,
          'enabled_identities' => ['keycloak'],
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
          ],
          'flags' => Hash[UserFlags.flag_names.map {|f| [f, false]}],
          'is_managerial' => true,
          'is_technical' => true
        })
      end
    end
  end

  describe '#complete_hub_onboarding' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show
      end
    end

    it_behaves_like 'authenticated' do
      before do
        u = current_user
        @current_is_managerial_value = u.is_managerial
        @current_is_technical_value = u.is_technical
      end

      let :post_data do
        {
          is_managerial: !@current_is_managerial_value,
          is_technical: !@current_is_technical_value
        }
      end

      it 'should make the necessary user updates and return the updated me resource' do
        expect(current_user.flags.completed_hub_onboarding).to be false
        post :complete_hub_onboarding, params: post_data
        expect(response).to be_success
        expect(json_response['is_managerial']).to eq !@current_is_managerial_value
        expect(json_response['is_technical']).to eq !@current_is_technical_value
        expect(json_response['flags']['completed_hub_onboarding']).to be true
        expect(Audit.count).to eq 1
        audit = Audit.first
        expect(audit.action).to eq 'complete_hub_onboarding'
        expect(audit.user.id).to eq current_user_id
      end
    end
  end

  describe '#complete_services_onboarding' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show
      end
    end

    it_behaves_like 'authenticated' do

      let :git_hub_agent_service do
        instance_double('Agents::GitHubAgentService')
      end

      context 'when user does not have a GitHub identity connected' do
        it 'should return a 400 Bad Request with an appropriate error message' do
          expect(Agents::GitHubAgentService).to receive(:new).with(any_args).and_return(git_hub_agent_service)
          expect(git_hub_agent_service).to receive(:onboard_user).with(current_user).and_raise(Agents::GitHubAgentService::Errors::IdentityMissing)
          post :complete_services_onboarding
          expect(response).to have_http_status(400)
          expect(json_response['error']['message']).to eq 'User does not have a GitHub identity connected yet'
          expect(Audit.count).to be 0
        end
      end

      context 'when user has a GitHub identity connected' do
        it 'should onboard the user and return a success response with no content' do
          expect(Agents::GitHubAgentService).to receive(:new).with(any_args).and_return(git_hub_agent_service)
          expect(git_hub_agent_service).to receive(:onboard_user).with(current_user).and_return(true)
          expect(current_user.flags.completed_services_onboarding).to be false
          get :complete_services_onboarding
          expect(response).to be_success
          expect(json_response['flags']['completed_services_onboarding']).to be true
          expect(Audit.count).to eq 2
          audits = Audit.all
          expect(audits.first.action).to eq 'onboard_github'
          expect(audits.first.auditable).to eq current_user
          expect(audits.first.user.id).to eq current_user_id
          expect(audits.second.action).to eq 'complete_services_onboarding'
          expect(audits.second.user.id).to eq current_user_id
        end
      end

    end
  end

end
