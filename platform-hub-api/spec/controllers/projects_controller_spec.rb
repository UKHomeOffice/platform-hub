require 'rails_helper'

RSpec.describe ProjectsController, type: :controller do

  include_context 'time helpers'

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @projects = create_list :project, 3
      end

      let :total_projects do
        @projects.length
      end

      let :all_project_ids do
        @projects.map(&:friendly_id)
      end

      it 'should return a list of all projects' do
        get :index
        expect(response).to be_success
        expect(json_response.length).to eq total_projects
        expect(pluck_from_json_response('id')).to match_array all_project_ids
      end

    end
  end

  describe 'GET #show' do
    before do
      @project = create :project
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @project.friendly_id }
      end
    end

    it_behaves_like 'authenticated' do

      context 'for a non-existent project' do
        it 'should return a 404' do
          get :show, params: { id: 'unknown' }
          expect(response).to have_http_status(404)
        end
      end

      context 'for a project that exists' do
        context 'for a regular user' do
          it 'should return the specified project resource with no protected fields' do
            get :show, params: { id: @project.friendly_id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @project.friendly_id,
              'shortname' => @project.shortname,
              'name' => @project.name,
              'description' => @project.description,
              'members_count' => 0,
              'created_at' => now_json_value,
              'updated_at' => now_json_value,
            })
          end
        end

        it_behaves_like 'an admin' do
          it 'should return the specified project resource with protected fields' do
            get :show, params: { id: @project.friendly_id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @project.friendly_id,
              'shortname' => @project.shortname,
              'name' => @project.name,
              'description' => @project.description,
              'members_count' => 0,
              'cost_centre_code' => @project.cost_centre_code,
              'created_at' => now_json_value,
              'updated_at' => now_json_value,
            })
          end
        end

        context 'not an admin but is project manager' do
          before do
            create :project_membership_as_manager, project: @project, user: current_user
          end

          it 'should return the specified project resource with protected fields' do
            get :show, params: { id: @project.friendly_id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @project.friendly_id,
              'shortname' => @project.shortname,
              'name' => @project.name,
              'description' => @project.description,
              'members_count' => 1,
              'cost_centre_code' => @project.cost_centre_code,
              'created_at' => now_json_value,
              'updated_at' => now_json_value,
            })
          end
        end
      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      {
        project: {
          shortname: 'foo',
          name: 'foobar',
          description: 'swimming in foobar',
          cost_centre_code: 'SUPEREXPENSIVE'
        }
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :create, params: post_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :create, params: post_data
        end
      end

      it_behaves_like 'an admin' do

        it 'creates a new project as expected' do
          expect(Project.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(Project.count).to eq 1
          project = Project.first
          new_project_external_id = project.friendly_id
          new_project_internal_id = project.id
          expect(json_response).to eq({
            'id' => new_project_external_id,
            'shortname' => post_data[:project][:shortname],
            'name' => post_data[:project][:name],
            'description' => post_data[:project][:description],
            'members_count' => 0,
            'cost_centre_code' => post_data[:project][:cost_centre_code],
            'created_at' => now_json_value,
            'updated_at' => now_json_value
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq new_project_internal_id
          expect(audit.user.id).to eq current_user_id
        end

        context 'with existing projects' do
          before do
            @existing_project = create :project
          end

          it 'fails to create a new project with a shortname that\'s already taken' do
            post_data_with_same_shortname = {
              project: post_data[:project].clone.tap { |h| h[:shortname] = @existing_project.shortname }
            }
            expect(Project.count).to eq 1
            expect(Audit.count).to eq 0
            post :create, params: post_data_with_same_shortname
            expect(response).to have_http_status(422)
            expect(json_response['error']['message']).not_to be_empty
            expect(Project.count).to eq 1
            expect(Audit.count).to eq 0
          end
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @project.friendly_id,
        project: {
          shortname: 'foo',
          name: 'foobar',
          cost_centre_code: 'NOTSOEXPENSIVENOW'
        }
      }
    end

    let :existing_description do
      'so much foobar'
    end

    before do
      @project = create :project, description: existing_description
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :update, params: put_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          put :update, params: put_data
        end
      end

      it_behaves_like 'an admin' do

        it 'updates the specified project' do
          expect(Project.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_data
          expect(response).to be_success
          expect(Project.count).to eq 1
          updated = Project.first
          expect(updated.shortname).to eq put_data[:project][:shortname]
          expect(updated.name).to eq put_data[:project][:name]
          expect(updated.description).to eq existing_description
          expect(updated.cost_centre_code).to eq put_data[:project][:cost_centre_code]
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update'
          expect(audit.auditable.id).to eq @project.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @project = create :project
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @project.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { id: @project.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should delete the specified project' do
          expect(Project.exists?(@project.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @project.id }
          expect(response).to be_success
          expect(Project.exists?(@project.id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'GET #memberships' do
    before do
      @project = create :project
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :memberships, params: { id: @project.id }
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @users = create_list(:user, 2).sort_by(&:name)
        @memberships = @users.map do |u|
          create :project_membership, project: @project, user: u
        end
      end

      let :results do
        # Important: we shouldn't be able to see the user's identities here
        # (since we're not an admin)

        @memberships.map do |m|
          user = m.user

          {
            'user' => {
              'id' => user.id,
              'name' => user.name,
              'email' => user.email,
              'role' =>  user.role,
              'last_seen_at' => now_json_value,
              'enabled_identities' => [],
              'is_active' => true,
              'is_managerial' => true,
              'is_technical' => true
            },
            'role' => nil
          }
        end
      end

      it 'should return a list of memberships' do
        get :memberships, params: { id: @project.id }
        expect(response).to be_success
        expect(json_response).to eq results
      end

    end
  end

  describe 'PUT #add_membership' do
    before do
      @project = create :project
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :add_membership, params: { id: @project.id, user_id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          put :add_membership, params: { id: @project.id, user_id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should add the specified user to the project membership list' do
          expect(@project.memberships.count).to eq 0
          expect(Audit.count).to eq 0
          put :add_membership, params: { id: @project.id, user_id: @user.id }
          expect(response).to be_success
          expect(@project.memberships.count).to eq 1
          expect(@project.memberships.first.user_id).to eq @user.id
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'add_membership'
          expect(audit.auditable.id).to eq @project.id
          expect(audit.associated.id).to eq @user.id
          expect(audit.user.id).to eq current_user_id
        end

      end

      context 'not an admin but is project manager of same project' do
        before do
          create :project_membership_as_manager, project: @project, user: current_user
        end

        it 'should add the specified user to the project membership list' do
          expect(@project.memberships.count).to eq 1
          expect(Audit.count).to eq 0
          put :add_membership, params: { id: @project.id, user_id: @user.id }
          expect(response).to be_success
          expect(@project.memberships.count).to eq 2
          expect(@project.memberships.exists?(user_id: @user.id)).to be true
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'add_membership'
          expect(audit.auditable.id).to eq @project.id
          expect(audit.associated.id).to eq @user.id
          expect(audit.user.id).to eq current_user_id
        end
      end

      context 'not an admin but is project manager of a different project' do
        before do
          another_project = create :project
          create :project_membership_as_manager, project: another_project, user: current_user
        end

        it 'should not be able to add the user to the project team - returning 403 Forbidden' do
          put :add_membership, params: { id: @project.id, user_id: @user.id }
          expect(response).to have_http_status(403)
        end
      end

    end
  end

  describe 'DELETE #remove_membership' do
    before do
      @project = create :project
      @user = create :user
      @membership = create :project_membership, project: @project, user: @user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :remove_membership, params: { id: @project.id, user_id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          put :remove_membership, params: { id: @project.id, user_id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should remove the specified user from the project membership list' do
          expect(@project.memberships.count).to eq 1
          expect(Audit.count).to eq 0
          put :remove_membership, params: { id: @project.id, user_id: @user.id }
          expect(response).to be_success
          expect(@project.memberships.count).to eq 0
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'remove_membership'
          expect(audit.auditable.id).to eq @project.id
          expect(audit.associated.id).to eq @user.id
          expect(audit.user.id).to eq current_user_id
        end

      end

      context 'not an admin but is project manager of same project' do
        before do
          create :project_membership_as_manager, project: @project, user: current_user
        end

        it 'should remove the specified user from the project membership list' do
          expect(@project.memberships.count).to eq 2
          expect(Audit.count).to eq 0
          put :remove_membership, params: { id: @project.id, user_id: @user.id }
          expect(response).to be_success
          expect(@project.memberships.count).to eq 1
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'remove_membership'
          expect(audit.auditable.id).to eq @project.id
          expect(audit.associated.id).to eq @user.id
          expect(audit.user.id).to eq current_user_id
        end
      end

      context 'not an admin but is project manager of a different project' do
        before do
          another_project = create :project
          create :project_membership_as_manager, project: another_project, user: current_user
        end

        it 'should not be able to remove the user from the project team - returning 403 Forbidden' do
          put :remove_membership, params: { id: @project.id, user_id: @user.id }
          expect(response).to have_http_status(403)
        end
      end

    end
  end

  describe 'GET #role_check' do
    let :role do
      'manager'
    end

    before do
      @project = create :project
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :role_check, params: { id: @project.friendly_id, role: role }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_result result
        get :role_check, params: { id: @project.friendly_id, role: role }
        expect(response).to be_success
        expect(json_response['result']).to eq result
      end

      context 'not an admin' do

        context 'and not a member of the project' do
          it 'should return a false result' do
            expect_result false
          end
        end

        context 'is a member of the project but not a manager' do
          before do
            create :project_membership, project: @project, user: current_user
          end

          it 'should return a false result' do
            expect_result false
          end
        end

        context 'is a manager for the project' do
          before do
            create :project_membership_as_manager, project: @project, user: current_user
          end

          it 'should return a true result' do
            expect_result true
          end
        end

        context 'is manager of a different project' do
          before do
            another_project = create :project
            create :project_membership_as_manager, project: another_project, user: current_user
          end

          it 'should return a false result' do
            expect_result false
          end
        end

      end

      it_behaves_like 'an admin' do

        context 'but not a member or manager for the project' do
          it 'should return a false result' do
            expect_result false
          end
        end

        context 'is a manager for the project' do
          before do
            create :project_membership_as_manager, project: @project, user: current_user
          end

          it 'should return a true result' do
            expect_result true
          end
        end

      end

    end
  end

  describe 'PUT #set_role' do
    let :role do
      'manager'
    end

    before do
      @project = create :project
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :set_role, params: { id: @project.id, user_id: @user.id, role: role }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          put :set_role, params: { id: @project.id, user_id: @user.id, role: role }
        end
      end

      it_behaves_like 'an admin' do

        context 'when user is not a project team member' do
          it 'should return a 400 Bad Request error' do
            put :set_role, params: { id: @project.id, user_id: @user.id, role: role }
            expect(response).to have_http_status(400)
          end
        end

        context 'when user is a project team member' do
          before do
            create :project_membership, project: @project, user: @user
          end

          it 'should set the role accordingly' do
            expect(ProjectMembership.exists?(project_id: @project.id, user_id: @user.id, role: role)).to be false
            expect(Audit.count).to eq 0
            put :set_role, params: { id: @project.id, user_id: @user.id, role: role }
            expect(response).to be_success
            expect(json_response['role']).to eq role
            expect(ProjectMembership.exists?(project_id: @project.id, user_id: @user.id, role: role)).to be true
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'set_role'
            expect(audit.auditable.id).to eq @project.id
            expect(audit.associated.id).to eq @user.id
            expect(audit.user.id).to eq current_user_id
            expect(audit.data['previous_role']).to eq nil
            expect(audit.data['new_role']).to eq role
          end
        end

      end

    end
  end

  describe 'DELETE #unset_role' do
    let :role do
      'manager'
    end

    before do
      @project = create :project
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :unset_role, params: { id: @project.id, user_id: @user.id, role: role }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :unset_role, params: { id: @project.id, user_id: @user.id, role: role }
        end
      end

      it_behaves_like 'an admin' do

        context 'when user is not a project team member' do
          it 'should return a 400 Bad Request error' do
            delete :unset_role, params: { id: @project.id, user_id: @user.id, role: role }
            expect(response).to have_http_status(400)
          end
        end

        context 'when user is a project team member and has the role specified' do
          before do
            create :project_membership, project: @project, user: @user, role: role
          end

          it 'should unset the role accordingly' do
            expect(ProjectMembership.exists?(project_id: @project.id, user_id: @user.id, role: role)).to be true
            expect(Audit.count).to eq 0
            delete :unset_role, params: { id: @project.id, user_id: @user.id, role: role }
            expect(response).to be_success
            expect(json_response['role']).to eq nil
            expect(ProjectMembership.exists?(project_id: @project.id, user_id: @user.id, role: role)).to be false
            expect(ProjectMembership.exists?(project_id: @project.id, user_id: @user.id, role: nil)).to be true
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'unset_role'
            expect(audit.auditable.id).to eq @project.id
            expect(audit.associated.id).to eq @user.id
            expect(audit.user.id).to eq current_user_id
            expect(audit.data['previous_role']).to eq role
            expect(audit.data['new_role']).to eq nil
          end
        end

      end

    end
  end

  describe 'GET #kubernetes_clusters' do
    before do
      @project = create :project
      @other_project = create :project
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :kubernetes_clusters, params: { id: @project.id }
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @project_cluster_1 = create :kubernetes_cluster, allocate_to: @project
        @other_project_cluster = create :kubernetes_cluster, allocate_to: @other_project
        @project_cluster_2 = create :kubernetes_cluster, allocate_to: @project

        # Unallocated clusters
        create_list :kubernetes_cluster, 2
      end

      let :project_clusters do
        [
          @project_cluster_1,
          @project_cluster_2
        ].sort_by(&:name)
      end

      let :other_project_clusters do
        [
          @other_project_cluster
        ].sort_by(&:name)
      end

      def expect_clusters project, clusters
        get :kubernetes_clusters, params: { id: project.id }
        expect(response).to be_success
        expect(pluck_from_json_response('name')).to match_array clusters.map(&:name)
      end

      it_behaves_like 'an admin' do

        it 'can fetch clusters for the project as expected' do
          expect_clusters @project, project_clusters
        end

        it 'can fetch clusters for the other project as expected' do
          expect_clusters @other_project, other_project_clusters
        end

      end

      context 'not an admin but is manager of the project' do

        before do
          create :project_membership_as_manager, project: @project, user: current_user
        end

        it 'can fetch clusters for the project as expected' do
          expect_clusters @project, project_clusters
        end

        it 'cannot fetch clusters for the other project - returning 403 Forbidden' do
          get :kubernetes_clusters, params: { id: @other_project.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not an admin but is a member of the project' do

        before do
          create :project_membership, project: @project, user: current_user
        end

        it 'can fetch clusters for the project as expected' do
          expect_clusters @project, project_clusters
        end

        it 'cannot fetch clusters for the other project - returning 403 Forbidden' do
          get :kubernetes_clusters, params: { id: @other_project.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not an admin but is manager of the other project' do

        before do
          create :project_membership_as_manager, project: @other_project, user: current_user
        end

        it 'cannot fetch clusters for the project - returning 403 Forbidden' do
          get :kubernetes_clusters, params: { id: @project.id }
          expect(response).to have_http_status(403)
        end

        it 'can fetch clusters for the other project as expected' do
          expect_clusters @other_project, other_project_clusters
        end

      end

      context 'not an admin but is a member of other project' do

        before do
          create :project_membership, project: @other_project, user: current_user
        end

        it 'cannot fetch clusters for the project - returning 403 Forbidden' do
          get :kubernetes_clusters, params: { id: @project.id }
          expect(response).to have_http_status(403)
        end

        it 'can fetch clusters for the other project as expected' do
          expect_clusters @other_project, other_project_clusters
        end

      end

    end
  end

  describe 'GET #kubernetes_groups' do
    before do
      @project = create :project
      @other_project = create :project
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :kubernetes_groups, params: { id: @project.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_groups project, target, groups
        params = { id: project.id }
        params[:target] = target if target
        get :kubernetes_groups, params: params
        expect(response).to be_success
        expect(pluck_from_json_response('name')).to match_array groups.map(&:name)
      end

      it_behaves_like 'an admin' do

        context 'no target specified' do
          it 'can fetch groups for the project as expected' do
            expect_groups @project, nil, []
          end

          it 'can fetch groups for the other project as expected' do
            expect_groups @other_project, nil, []
          end
        end

        context 'target=user' do
          it 'can fetch groups for the project as expected' do
            expect_groups @project, 'user', []
          end

          it 'can fetch groups for the other project as expected' do
            expect_groups @other_project, 'user', []
          end
        end

        context 'target=robot' do
          it 'can fetch groups for the project as expected' do
            expect_groups @project, 'robot', []
          end

          it 'can fetch groups for the other project as expected' do
            expect_groups @other_project, 'robot', []
          end
        end

        it 'should return a 400 error for an invalid target' do
          get :kubernetes_groups, params: { id: @project.id, target: 'invalid' }
          expect(response).to have_http_status(400)
        end

      end

      # NOTE: we don't need to repeat the target filtering specs anymore

      context 'not an admin but is manager of the project' do

        before do
          create :project_membership_as_manager, project: @project, user: current_user
        end

        it 'can fetch groups for the project as expected' do
          expect_groups @project, nil, []
        end

        it 'cannot fetch groups for the other project - returning 403 Forbidden' do
          get :kubernetes_groups, params: { id: @other_project.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not an admin but is a member of the project' do

        before do
          create :project_membership, project: @project, user: current_user
        end

        it 'can fetch groups for the project as expected' do
          expect_groups @project, nil, []
        end

        it 'cannot fetch groups for the other project - returning 403 Forbidden' do
          get :kubernetes_groups, params: { id: @other_project.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not an admin but is manager of the other project' do

        before do
          create :project_membership_as_manager, project: @other_project, user: current_user
        end

        it 'cannot fetch groups for the project - returning 403 Forbidden' do
          get :kubernetes_groups, params: { id: @project.id }
          expect(response).to have_http_status(403)
        end

        it 'can fetch groups for the other project as expected' do
          expect_groups @other_project, nil, []
        end

      end

      context 'not an admin but is a member of other project' do

        before do
          create :project_membership, project: @other_project, user: current_user
        end

        it 'cannot fetch groups for the project - returning 403 Forbidden' do
          get :kubernetes_groups, params: { id: @project.id }
          expect(response).to have_http_status(403)
        end

        it 'can fetch groups for the other project as expected' do
          expect_groups @other_project, nil, []
        end

      end

    end
  end

end
