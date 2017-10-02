require 'rails_helper'

RSpec.describe UsersController, type: :controller do

  include_context 'time helpers'

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :index
        end
      end

      it_behaves_like 'an admin' do

        context 'when only the authenticated user exists' do
          it 'should return a list with only the authenticated user' do
            get :index
            expect(response).to be_success
            expect(pluck_from_json_response('id')).to eq [current_user_id]
          end
        end

        context 'when multiple users exist' do
          before do
            @users = create_list :user, 3
          end

          let :total_users do
            @users.length + 1
          end

          let :all_user_ids do
            @users.map(&:id) + [current_user_id]
          end

          it 'should return a list of all the users' do
            # Remember, the currently authenticated user should also be in the list
            get :index
            expect(response).to be_success
            expect(json_response.length).to eq total_users
            expect(pluck_from_json_response('id')).to match_array all_user_ids
          end
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :show, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        context 'for a non-existent user' do
          it 'should return a 404' do
            get :show, params: { id: 'foo' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a user that exists' do
          it 'should return the specified user resource' do
            get :show, params: { id: @user.id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @user.id,
              'name' => @user.name,
              'email' => @user.email,
              'role' => nil,
              'last_seen_at' => now_json_value,
              'enabled_identities' => [],
              'flags' => Hash[UserFlags.flag_names.map {|f| [f, false]}],
              'is_active' => true,
              'is_managerial' => true,
              'is_technical' => true
            })
          end
        end

      end

    end
  end

  describe 'GET #search' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :search, params: { q: 'foo' }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :search, params: { q: 'foo' }
        end
      end

      it_behaves_like 'an admin' do

        context 'when no users exist' do
          it 'should not return any results' do
            get :search, params: { q: 'foo' }
            expect(response).to be_success
            expect(json_response.length).to eq 0
          end
        end

        context 'when users exist and include_deactivated param is true' do
          before do
            create_list :user, 3
            @user = create :user, name: 'foobar', is_active: false
          end

          it 'should return expected results' do
            get :search, params: { q: 'foo', include_deactivated: 'true' }
            expect(response).to be_success
            expect(json_response.length).to eq 1
            expect(json_response.first['id']).to eq @user.id
          end
        end

        context 'when users exist and include_deactivated param is false' do
          before do
            create_list :user, 3
            @user = create :user, name: 'foobar', is_active: false
          end

          it 'filters out deactivated users' do
            get :search, params: { q: 'foo', include_deactivated: 'false' }
            expect(response).to be_success
            expect(json_response.length).to eq 0
          end
        end
      end

      context 'not an admin but is a project manager of some project' do
        before do
          project = create :project
          create :project_membership_as_manager, project: project, user: current_user

          create_list :user, 3
          @user = create :user, name: 'foobar'
        end

        it 'should return expected results' do
          get :search, params: { q: 'foo' }
          expect(response).to be_success
          expect(json_response.length).to eq 1
          expect(json_response.first['id']).to eq @user.id
        end
      end

    end
  end

  describe 'GET #identities' do
    let(:identity) { build :identity }

    before do
      @user = create :user, identities: [ identity ]
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :identities, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_identities target_user, identity
        get :identities, params: { id: target_user }
        expect(response).to be_success
        expect(json_response.length).to eq 1
        expect(json_response).to eq([
          {
            'provider' => identity.provider,
            'external_id' => identity.external_id,
            'external_username' => identity.external_username,
            'external_name' => identity.external_name,
            'external_email' => identity.external_email,
            'created_at' => identity.created_at.iso8601,
            'updated_at' => identity.updated_at.iso8601
          }
        ])
      end

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :identities, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do
        it 'should return the user\'s list of identities' do
          expect_identities @user, identity
        end
      end

      context 'not an admin and a different user' do
        it 'should not be able to load identities - returning 403 Forbidden' do
          get :identities, params: { id: @user.id }
          expect(response).to have_http_status(403)
        end
      end

      context 'not an admin but same user' do
        it 'should be able to load your own identities' do
          expect_identities current_user, current_user.identities.first
        end
      end

    end
  end

  describe 'POST #make_admin' do
    before do
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :make_admin, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :make_admin, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should make the specified user an admin' do
          expect(@user.admin?).to be false
          expect(Audit.count).to eq 0
          post :make_admin, params: { id: @user.id }
          expect(response).to be_success
          expect(@user.reload.admin?).to be true
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'make_admin'
          expect(audit.auditable).to eq @user
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'POST #revoke_admin' do
    before do
      @user = create :admin_user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :revoke_admin, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :revoke_admin, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should revoke the admin role for the specified user' do
          expect(@user.admin?).to be true
          expect(Audit.count).to eq 0
          post :revoke_admin, params: { id: @user.id }
          expect(response).to be_success
          expect(@user.reload.admin?).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'revoke_admin'
          expect(audit.auditable).to eq @user
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'POST #onboard_github' do

    before do
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :onboard_github, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      let :git_hub_agent_service do
        instance_double('Agents::GitHubAgentService')
      end

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :onboard_github, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        context 'when user does not have a GitHub identity connected' do
          it 'should return a 400 Bad Request with an appropriate error message' do
            expect(Agents::GitHubAgentService).to receive(:new).with(any_args).and_return(git_hub_agent_service)
            expect(git_hub_agent_service).to receive(:onboard_user).with(@user).and_raise(Agents::GitHubAgentService::Errors::IdentityMissing)
            post :onboard_github, params: { id: @user.id }
            expect(response).to have_http_status(400)
            expect(json_response['error']['message']).to eq 'User does not have a GitHub identity connected yet'
            expect(Audit.count).to be 0
          end
        end

        context 'when user has a GitHub identity connected' do
          it 'should onboard the user and return a success response with no content' do
            expect(Agents::GitHubAgentService).to receive(:new).with(any_args).and_return(git_hub_agent_service)
            expect(git_hub_agent_service).to receive(:onboard_user).with(@user).and_return(true)
            post :onboard_github, params: { id: @user.id }
            expect(response).to have_http_status(204)
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'onboard_github'
            expect(audit.auditable).to eq @user
            expect(audit.user.id).to eq current_user_id
          end
        end

      end

      context 'not an admin but is project manager of same project' do
        before do
          project = create :project
          create :project_membership, project: project, user: @user
          create :project_membership_as_manager, project: project, user: current_user
        end

        it 'should onboard the user and return a success response with no content' do
          expect(Agents::GitHubAgentService).to receive(:new).with(any_args).and_return(git_hub_agent_service)
          expect(git_hub_agent_service).to receive(:onboard_user).with(@user).and_return(true)
          post :onboard_github, params: { id: @user.id }
          expect(response).to have_http_status(204)
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'onboard_github'
          expect(audit.auditable).to eq @user
          expect(audit.user.id).to eq current_user_id
        end
      end

      context 'not an admin but is project manager but of a different and not common project' do
        before do
          project1 = create :project
          project2 = create :project
          create :project_membership, project: project1, user: @user
          create :project_membership, project: project1, user: current_user
          create :project_membership_as_manager, project: project2, user: current_user
        end

        it 'should not be able to onboard the user on GitHub - returning 403 Forbidden' do
          post :onboard_github, params: { id: @user.id }
          expect(response).to have_http_status(403)
          expect(Audit.count).to be 0
        end
      end

    end
  end

  describe 'POST #offboard_github' do

    before do
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :offboard_github, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      let :git_hub_agent_service do
        instance_double('Agents::GitHubAgentService')
      end

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :offboard_github, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        context 'when user does not have a GitHub identity connected' do
          it 'should return a 400 Bad Request with an appropriate error message' do
            expect(Agents::GitHubAgentService).to receive(:new).with(any_args).and_return(git_hub_agent_service)
            expect(git_hub_agent_service).to receive(:offboard_user).with(@user).and_raise(Agents::GitHubAgentService::Errors::IdentityMissing)
            post :offboard_github, params: { id: @user.id }
            expect(response).to have_http_status(400)
            expect(json_response['error']['message']).to eq 'User does not have a GitHub identity connected yet'
            expect(Audit.count).to be 0
          end
        end

        context 'when user has a GitHub identity connected' do
          it 'should offboard the user and return a success response with no content' do
            expect(Agents::GitHubAgentService).to receive(:new).with(any_args).and_return(git_hub_agent_service)
            expect(git_hub_agent_service).to receive(:offboard_user).with(@user).and_return(true)
            post :offboard_github, params: { id: @user.id }
            expect(response).to have_http_status(204)
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'offboard_github'
            expect(audit.auditable).to eq @user
            expect(audit.user.id).to eq current_user_id
          end
        end

      end

      context 'not an admin but is project manager of same project' do
        before do
          project = create :project
          create :project_membership, project: project, user: @user
          create :project_membership_as_manager, project: project, user: current_user
        end

        it 'should offboard the user and return a success response with no content' do
          expect(Agents::GitHubAgentService).to receive(:new).with(any_args).and_return(git_hub_agent_service)
          expect(git_hub_agent_service).to receive(:offboard_user).with(@user).and_return(true)
          post :offboard_github, params: { id: @user.id }
          expect(response).to have_http_status(204)
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'offboard_github'
          expect(audit.auditable).to eq @user
          expect(audit.user.id).to eq current_user_id
        end
      end

      context 'not an admin but is project manager but of a different and not common project' do
        before do
          project1 = create :project
          project2 = create :project
          create :project_membership, project: project1, user: @user
          create :project_membership, project: project1, user: current_user
          create :project_membership_as_manager, project: project2, user: current_user
        end

        it 'should not be able to offboard the user on GitHub - returning 403 Forbidden' do
          post :offboard_github, params: { id: @user.id }
          expect(response).to have_http_status(403)
          expect(Audit.count).to be 0
        end
      end

    end

  end

  describe 'POST #activate' do
    before do
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :activate, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :activate, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do
        let(:keycloak_agent_service) { instance_double('Agents::KeycloakAgentService') }
        let(:user_representation) { double }

        before do
          @user.deactivate!
        end

        it 'should activate the specified user' do
          expect(keycloak_agent_service).to receive(:activate_user).with(@user).and_return(user_representation)
          expect(UserActivationService).to receive(:keycloak_agent_service).and_return(keycloak_agent_service)

          expect(@user.is_active?).to be false
          expect(Audit.count).to eq 0
          expect(controller).to receive(:handle_user_activation_request).and_call_original
          expect(UserActivationService).to receive(:activate!).with(@user).and_call_original
          post :activate, params: { id: @user.id }
          expect(response).to be_success
          expect(@user.reload.is_active?).to be true
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'activate'
          expect(audit.auditable).to eq @user
          expect(audit.user.id).to eq current_user_id
        end

        context 'with user activation service error' do
          include_examples "verify responses to exceptions for user activation", :activate
        end

      end
    end
  end

  describe 'POST #deactivate' do
    before do
      @user = create :admin_user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :deactivate, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :deactivate, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do
        let(:keycloak_agent_service) { instance_double('Agents::KeycloakAgentService') }
        let(:user_representation) { double }

        it 'should deactivate the specified user' do
          expect(keycloak_agent_service).to receive(:deactivate_user).with(@user).and_return(user_representation)
          expect(UserActivationService).to receive(:keycloak_agent_service).and_return(keycloak_agent_service)

          expect(@user.is_active?).to be true
          expect(Audit.count).to eq 0
          expect(controller).to receive(:handle_user_deactivation_request).and_call_original
          expect(UserActivationService).to receive(:deactivate!).with(@user).and_call_original
          post :deactivate, params: { id: @user.id }
          expect(response).to be_success
          expect(@user.reload.is_active?).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'deactivate'
          expect(audit.auditable).to eq @user
          expect(audit.user.id).to eq current_user_id
        end

        context 'with user activation service error' do
          include_examples "verify responses to exceptions for user activation", :deactivate
        end

      end
    end
  end

end
