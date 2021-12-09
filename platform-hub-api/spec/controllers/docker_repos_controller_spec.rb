require 'rails_helper'

RSpec.describe DockerReposController, type: :controller do

  include_context 'time helpers'

  let!(:project) { create :project }
  let!(:service) { create :service, project: project }
  let!(:other_project) { create :project }
  let!(:other_service) { create :service, project: other_project }

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index, params: { project_id: project.friendly_id }
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @docker_repos = create_list :docker_repo, 3, service: service
      end

      let :total_docker_repos do
        @docker_repos.length
      end

      let :all_docker_repo_ids do
        @docker_repos.sort_by(&:name).map(&:id)
      end

      def expect_project_docker_repos
        get :index, params: { project_id: project.friendly_id }
        expect(response).to be_success
        expect(json_response.length).to eq total_docker_repos
        expect(pluck_from_json_response('id')).to match_array all_docker_repo_ids
      end

      def expect_other_project_docker_repos
        get :index, params: { project_id: other_project.friendly_id }
        expect(response).to be_success
        expect(json_response).to be_empty
      end

      context 'for a non-existent project' do
        it 'should return a 404' do
          get :index, params: { project_id: 'unknown' }
          expect(response).to have_http_status(404)
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should return a list of all docker repos for the project' do
          expect_project_docker_repos
        end

        it 'should return a list of all docker repos for the other project' do
          expect_other_project_docker_repos
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'should return a list of all docker repos for the project' do
          expect_project_docker_repos
        end

        it 'should not be able to list docker repos within the other project - returning 403 Forbidden' do
          get :index, params: { project_id: other_project.friendly_id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'should not be able to list docker repos within the project - returning 403 Forbidden' do
          get :index, params: { project_id: project.friendly_id }
          expect(response).to have_http_status(403)
        end

        it 'should return a list of all docker repos for the other project' do
          expect_other_project_docker_repos
        end

      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      {
        docker_repo: {
          name: 'fooo',
          description: 'so much fooooo'
        }
      }
    end

    let(:lifecycle_service) { instance_double('DockerRepoLifecycleService') }

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :create, params: { project_id: project.friendly_id }.merge(post_data)
      end
    end

    it_behaves_like 'authenticated' do

      def expect_create_docker_repo service
        params = ActionController::Parameters.new(post_data[:docker_repo]).permit!
        docker_repo = create :docker_repo, service: service

        expect(DockerRepoLifecycleService).to receive(:new)
          .and_return(lifecycle_service)
        expect(lifecycle_service).to receive(:request_create)
          .with(service, params, anything)
          .and_return(docker_repo)

        post :create, params: {
          project_id: service.project.friendly_id,
          service_id: service.id
        }.merge(post_data)
        expect(response).to be_success
        expect(json_response).to include(
          'id' => docker_repo.id,
          'name' => docker_repo.name,
          'base_uri' => docker_repo.base_uri,
          'description' => docker_repo.description,
          'status' => docker_repo.status,
          'provider'=> docker_repo.provider,
          'created_at' => docker_repo.created_at.iso8601,
          'updated_at' => docker_repo.updated_at.iso8601
        )
      end

      it_behaves_like 'a hub admin' do

        it 'can create a new docker repo in the project as expected' do
          expect_create_docker_repo service
        end

        it 'can create a new docker repo in the other project as expected' do
          expect_create_docker_repo other_service
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot create a new docker repo in the project - returning 403 Forbidden' do
          post :create, params: { project_id: project.friendly_id }
          expect(response).to have_http_status(403)
        end

        it 'cannot create a new docker repo in the other project - returning 403 Forbidden' do
          post :create, params: { project_id: other_project.friendly_id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot create a new docker repo in the project - returning 403 Forbidden' do
          post :create, params: { project_id: project.friendly_id }
          expect(response).to have_http_status(403)
        end

        it 'cannot create a new docker repo in the other project - returning 403 Forbidden' do
          post :create, params: { project_id: other_project.friendly_id }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    let(:lifecycle_service) { instance_double('DockerRepoLifecycleService') }

    before do
      @docker_repo = create :docker_repo, service: service
      @other_docker_repo = create :docker_repo, service: other_service
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { project_id: project.friendly_id, id: @docker_repo.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_destroy_docker_repo project, docker_repo
        expect(DockerRepoLifecycleService).to receive(:new)
          .and_return(lifecycle_service)
        expect(lifecycle_service).to receive(:request_delete!)
          .with(docker_repo, anything)

        delete :destroy, params: { project_id: project.friendly_id, id: docker_repo.id }
        expect(response).to be_success
      end

      it_behaves_like 'a hub admin' do

        it 'can delete a docker_repo in the project as expected' do
          expect_destroy_docker_repo project, @docker_repo
        end

        it 'can delete a docker_repo in the other project as expected' do
          expect_destroy_docker_repo other_project, @other_docker_repo
        end

        it 'should return a 404 for incorrect matching of project and docker repo' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @docker_repo.id }
          expect(response).to have_http_status(404)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot delete a docker repo in the project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: project.friendly_id, id: @docker_repo.id }
          expect(response).to have_http_status(403)
        end

        it 'cannot delete a docker repo in the other project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @other_docker_repo.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot delete a docker repo in the project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: project.friendly_id, id: @docker_repo.id }
          expect(response).to have_http_status(403)
        end

        it 'cannot delete a docker repo in the other project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @other_docker_repo.id }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

  describe 'PUT #update_access' do
    let :robots do
      [
        { username: 'deploy1' },
        { username: 'deploy2' },
      ]
    end
    let :users do
      [
        { username: 'bob@bob.com', writable: false },
        { username: 'jo@jo.com', writable: true },
      ]
    end

    let(:access_policy_service) { instance_double('DockerRepoAccessPolicyService') }

    before do
      @docker_repo = create :docker_repo, service: service
      @other_docker_repo = create :docker_repo, service: other_service
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :update_access, params: { project_id: project.friendly_id, id: @docker_repo.id, robots: robots, users: users }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_update_access_docker_repo project, docker_repo, robots, users
        expect(DockerRepoAccessPolicyService).to receive(:new)
          .with(docker_repo)
          .and_return(access_policy_service)
        expect(access_policy_service).to receive(:request_update!)
          .with(robots, users, anything)

        put :update_access, params: { project_id: project.friendly_id, id: docker_repo.id, robots: robots, users: users }
        expect(response).to be_success
      end

      it_behaves_like 'a hub admin' do

        it 'can update access for a docker_repo in the project as expected' do
          expect_update_access_docker_repo project, @docker_repo, robots, users
        end

        it 'can update access for a docker_repo in the other project as expected' do
          expect_update_access_docker_repo other_project, @other_docker_repo, robots, users
        end

        it 'should return a 404 for incorrect matching of project and docker repo' do
          put :update_access, params: { project_id: other_project.friendly_id, id: @docker_repo.id, robots: robots, users: users }
          expect(response).to have_http_status(404)
        end

        it 'should allow empty lists' do
          expect_update_access_docker_repo project, @docker_repo, [], []
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot update access for a docker repo in the project - returning 403 Forbidden' do
          put :update_access, params: { project_id: project.friendly_id, id: @docker_repo.id, robots: robots, users: users }
          expect(response).to have_http_status(403)
        end

        it 'cannot update access for a docker repo in the other project - returning 403 Forbidden' do
          put :update_access, params: { project_id: other_project.friendly_id, id: @other_docker_repo.id, robots: robots, users: users }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot update access for a docker repo in the project - returning 403 Forbidden' do
          put :update_access, params: { project_id: project.friendly_id, id: @docker_repo.id, robots: robots, users: users }
          expect(response).to have_http_status(403)
        end

        it 'cannot update access for a docker repo in the other project - returning 403 Forbidden' do
          put :update_access, params: { project_id: other_project.friendly_id, id: @other_docker_repo.id, robots: robots, users: users }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

end
