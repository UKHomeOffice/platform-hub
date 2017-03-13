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
              'identities' => []
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

        context 'when users exist' do
          before do
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

      context 'not an admin but is a project team manager of some project' do
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
          get :make_admin, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should make the specified user an admin' do
          expect(@user.admin?).to be false
          expect(Audit.count).to eq 0
          get :make_admin, params: { id: @user.id }
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
          get :revoke_admin, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should revoke the admin role for the specified user' do
          expect(@user.admin?).to be true
          expect(Audit.count).to eq 0
          get :revoke_admin, params: { id: @user.id }
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
    let :git_hub_agent_service do
      instance_double('Agents::GitHubAgentService')
    end

    before do
      @user = create :user
      allow(Agents::GitHubAgentService).to receive(:new).with(any_args).and_return(git_hub_agent_service)
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :onboard_github, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :onboard_github, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        context 'when user does not have a GitHub identity connected' do
          it 'should return a 400 Bad Request with an appropriate error message' do
            expect(git_hub_agent_service).to receive(:onboard_user).with(@user).and_raise(Agents::GitHubAgentService::Errors::IdentityMissing)
            get :onboard_github, params: { id: @user.id }
            expect(response).to have_http_status(400)
            expect(json_response['error']['message']).to eq 'User does not have a GitHub identity connected yet'
          end
        end

        context 'when user has a GitHub identity connected' do
          it 'should onboard the user and return a success response with no content' do
            expect(git_hub_agent_service).to receive(:onboard_user).with(@user).and_return(true)
            get :onboard_github, params: { id: @user.id }
            expect(response).to have_http_status(204)
          end
        end

      end

      context 'not an admin but is project team manager of same team' do
        before do
          project = create :project
          create :project_membership, project: project, user: @user
          create :project_membership_as_manager, project: project, user: current_user
        end

        it 'should onboard the user and return a success response with no content' do
          expect(git_hub_agent_service).to receive(:onboard_user).with(@user).and_return(true)
          get :onboard_github, params: { id: @user.id }
          expect(response).to have_http_status(204)
        end
      end

      context 'not an admin but is project team manager but of a different team' do
        before do
          project1 = create :project
          project2 = create :project
          create :project_membership, project: project1, user: @user
          create :project_membership, project: project1, user: current_user
          create :project_membership_as_manager, project: project2, user: current_user
        end

        it 'should not be able to onboard the user on GitHub - returning 403 Forbidden' do
          get :onboard_github, params: { id: @user.id }
          expect(response).to have_http_status(403)
        end
      end

    end
  end

  describe 'POST #offboard_github' do
    # We expect the code path for `offboard_github` to be pretty much the same
    # as `onboard_github`, so rather than duplicating all the tests, we can
    # test just the auth bits and then rely on the specs for `onboard_github`
    # to give us confidence for the rest.

    before do
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :offboard_github, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :offboard_github, params: { id: @user.id }
        end
      end

      context 'not an admin but is project team manager but of a different team' do
        before do
          project1 = create :project
          project2 = create :project
          create :project_membership, project: project1, user: @user
          create :project_membership, project: project1, user: current_user
          create :project_membership_as_manager, project: project2, user: current_user
        end

        it 'should not be able to offboard the user on GitHub - returning 403 Forbidden' do
          get :offboard_github, params: { id: @user.id }
          expect(response).to have_http_status(403)
        end
      end

    end

  end

end
