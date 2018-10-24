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
          'flags' => Hash[UserFlags.flag_names.map {|f| [f, false]}],
          'is_active' => true,
          'is_managerial' => true,
          'is_technical' => true,
          'global_announcements_unread_count' => 0
        })
      end
    end
  end

  describe '#delete_identity' do
    it_behaves_like 'authenticated' do
      before do
        @identity = create(:identity,
          user: current_user
        )
      end

      context 'for an identity that exists' do
        it 'should delete the identity successfully' do
          expect(Audit.count).to eq 0
          delete :delete_identity, params: {service: @identity.provider}
          expect(response).to be_success
          expect(current_user.identity(@identity.provider)).to be nil
          expect(Audit.count).to eq 1
          expect(Audit.first.action).to eq 'delete_identity'
          expect(Audit.first.user.id).to eq current_user_id
        end
      end

      context 'for a non-existent identity' do
        it 'should fail and return a 404' do
          delete :delete_identity, params: {service: 'kubernetes'}
          expect(response).to have_http_status(404)
          expect(json_response['error']['message']).to eq "Resource not found"
          expect(Audit.count).to eq 0
        end
      end
    end
  end

  describe '#complete_hub_onboarding' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :complete_hub_onboarding
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

  describe '#agree_terms_of_service' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :agree_terms_of_service
      end
    end

    it_behaves_like 'authenticated' do
      it 'should mark the agreed_to_terms_of_service flag as true' do
        expect(current_user.flags.agreed_to_terms_of_service).to be false
        post :agree_terms_of_service
        expect(response).to be_success
        expect(json_response['flags']['agreed_to_terms_of_service']).to be true
        expect(Audit.count).to eq 1
        audit = Audit.first
        expect(audit.action).to eq 'agree_terms_of_service'
        expect(audit.user.id).to eq current_user_id
      end
    end
  end

  describe '#complete_services_onboarding' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :complete_services_onboarding
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

  describe '#global_announcements_mark_all_read' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :global_announcements_mark_all_read
      end
    end

    it_behaves_like 'authenticated' do
      before do
        # Make sure current_user exists in db before doing anything else
        current_user

        # New users get all announcements already marked unread, so let's play
        # with time to make sure we're well into the future
        move_time_to 1.day.from_now

        # We're now in the future… woohoo!
        create :announcement, is_global: true, publish_at: (now - 1.minute)
        create :announcement, is_global: true, publish_at: (now + 1.hour)
        create :announcement, is_global: false, publish_at: (now + 1.hour)
        create :announcement, is_global: true, publish_at: (now - 1.hour)
        create :announcement, is_global: false, publish_at: (now - 1.hour)
      end

      it 'marks all announcements as read' do
        # First, double check we're getting the correct count
        get :show
        expect(response).to be_success
        expect(json_response['global_announcements_unread_count']).to eq 2

        # Now mark all as readonly
        post :global_announcements_mark_all_read
        expect(response).to be_success
        expect(json_response['global_announcements_unread_count']).to eq 0
      end
    end
  end

  describe '#kubernetes_tokens' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :kubernetes_tokens
      end
    end

    it_behaves_like 'authenticated' do

      context 'when no kubernetes identity exists for the user' do
        it 'should return an empty list' do
          get :kubernetes_tokens
          expect(response).to be_success
          expect(json_response).to eq []
        end
      end

      context 'when a kubernetes identity exists for the user and has tokens associated' do
        before do
          @token = create :user_kubernetes_token, tokenable: create(:kubernetes_identity, user: current_user)
        end

        it 'should return a list of tokens with the token value revealed' do
          get :kubernetes_tokens
          expect(response).to be_success
          expect(json_response.length).to eq 1
          expect(json_response.first['cluster']['name']).to eq @token.cluster.name
          expect(json_response.first['token']).to eq @token.decrypted_token
          expect(json_response.first['obfuscated_token']).to eq @token.obfuscated_token
          expect(json_response.first['uid']).to eq @token.uid
          expect(json_response.first['name']).to eq @token.name
          expect(json_response.first['groups']).to match_array @token.groups
          expect(json_response.first['description']).to eq nil
          expect(json_response.first['kind']).to eq 'user'
        end
      end

    end
  end

end
