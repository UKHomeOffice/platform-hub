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
        @projects.map(&:id)
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
        get :show, params: { id: @project.id }
      end
    end

    it_behaves_like 'authenticated' do

      context 'for a non-existent project' do
        it 'should return a 404' do
          get :show, params: { id: 'foo' }
          expect(response).to have_http_status(404)
        end
      end

      context 'for a project that exists' do
        it 'should return the specified project resource' do
          get :show, params: { id: @project.id }
          expect(response).to be_success
          expect(json_response).to eq({
            'id' => @project.id,
            'shortname' => @project.shortname,
            'name' => @project.name,
            'description' => @project.description,
            'members_count' => 0,
            'created_at' => now_json_value,
            'updated_at' => now_json_value,
          })
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
          description: 'swimming in foobar'
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
          expect(Project.first.id).to eq json_response['id']
          expect(json_response).to eq({
            'id' => json_response['id'],
            'shortname' => post_data[:project][:shortname],
            'name' => post_data[:project][:name],
            'description' => post_data[:project][:description],
            'members_count' => 0,
            'created_at' => now_json_value,
            'updated_at' => now_json_value
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq json_response['id']
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @project.id,
        project: {
          shortname: 'foo',
          name: 'foobar'
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
          expect(Project.count).to eq 1
          updated = Project.first
          expect(updated.shortname).to eq put_data[:project][:shortname]
          expect(updated.name).to eq put_data[:project][:name]
          expect(updated.description).to eq existing_description
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
              'enabled_identities' => []
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

end
