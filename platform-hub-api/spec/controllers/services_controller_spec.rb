require 'rails_helper'

RSpec.describe ServicesController, type: :controller do

  include_context 'time helpers'

  let(:project) { create :project }
  let(:other_project) { create :project }

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index, params: { project_id: project.friendly_id }
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @services = create_list :service, 3, project: project
      end

      let :total_services do
        @services.length
      end

      let :all_service_ids do
        @services.sort_by(&:name).map(&:id)
      end

      def expect_project_services
        get :index, params: { project_id: project.friendly_id }
        expect(response).to be_success
        expect(json_response.length).to eq total_services
        expect(pluck_from_json_response('id')).to match_array all_service_ids
      end

      def expect_other_project_services
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

        it 'should return a list of all services for the project' do
          expect_project_services
        end

        it 'should return a list of all services for the other project' do
          expect_other_project_services
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'should return a list of all services for the project' do
          expect_project_services
        end

        it 'should not be able to list services within the other project - returning 403 Forbidden' do
          get :index, params: { project_id: other_project.friendly_id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'should not be able to list services within the project - returning 403 Forbidden' do
          get :index, params: { project_id: project.friendly_id }
          expect(response).to have_http_status(403)
        end

        it 'should return a list of all services for the other project' do
          expect_other_project_services
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @service = create :service, project: project
      @other_service = create :service, project: other_project
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :show, params: { project_id: project.friendly_id, id: @service.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_service
        get :show, params: { project_id: project.friendly_id, id: @service.id }
        expect(response).to be_success
        expect(json_response).to eq({
          'id' => @service.id,
          'name' => @service.name,
          'description' => @service.description,
          'project' => {
            'id' => project.friendly_id,
            'shortname' => project.shortname,
            'name' => project.name
          }
        })
      end

      def expect_other_service
        get :show, params: { project_id: other_project.friendly_id, id: @other_service.id }
        expect(response).to be_success
        expect(json_response).to eq({
          'id' => @other_service.id,
          'name' => @other_service.name,
          'description' => @other_service.description,
          'project' => {
            'id' => other_project.friendly_id,
            'shortname' => other_project.shortname,
            'name' => other_project.name
          }
        })
      end

      context 'for a non-existent service' do
        it 'should return a 404' do
          get :show, params: { project_id: project.friendly_id, id: 'nonexistent-service' }
          expect(response).to have_http_status(404)
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should return the service' do
          expect_service
        end

        it 'should return the other service' do
          expect_other_service
        end

        it 'should return a 404 for incorrect matching of project and service' do
          get :show, params: { project_id: project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(404)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'should return the service' do
          expect_service
        end

        it 'should not be able to return the other service within the other project - returning 403 Forbidden' do
          get :show, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'should not be able to return the service within the project - returning 403 Forbidden' do
          get :show, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'should return the other service' do
          expect_other_service
        end

      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      {
        service: {
          name: 'fooo',
          description: 'so much fooooo'
        }
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :create, params: { project_id: project.friendly_id }.merge(post_data)
      end
    end

    it_behaves_like 'authenticated' do

      def expect_create_service project
        expect(Service.count).to eq 0
        expect(Audit.count).to eq 0
        post :create, params: { project_id: project.friendly_id }.merge(post_data)
        expect(response).to be_success
        expect(Service.count).to eq 1
        service = Service.first
        expect(service.project).to eq project
        expect(json_response).to include(
          'id' => service.id,
          'name' => service.name,
          'description' => service.description
        )
        expect(Audit.count).to be 1
        audit = Audit.first
        expect(audit.action).to eq 'create'
        expect(audit.associated).to eq project
        expect(audit.auditable).to eq service
        expect(audit.user).to eq current_user
      end

      it_behaves_like 'a hub admin' do

        it 'can create a new service in the project as expected' do
          expect_create_service project
        end

        it 'can create a new service in the other project as expected' do
          expect_create_service other_project
        end

      end

      context 'not a hub admin but is an admin of the project' do

        before do
          create :project_membership_as_admin, project: project, user: current_user
        end

        it 'can create a new service in the project as expected' do
          expect_create_service project
        end

        it 'cannot create a new service in the other project - returning 403 Forbidden' do
          post :create, params: { project_id: other_project.friendly_id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot create a new service in the project - returning 403 Forbidden' do
          post :create, params: { project_id: project.friendly_id }
          expect(response).to have_http_status(403)
        end

        it 'cannot create a new service in the other project - returning 403 Forbidden' do
          post :create, params: { project_id: other_project.friendly_id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub admin but is an admin of the other project' do

        before do
          create :project_membership_as_admin, project: other_project, user: current_user
        end

        it 'cannot create a new service in the project - returning 403 Forbidden' do
          post :create, params: { project_id: project.friendly_id }
          expect(response).to have_http_status(403)
        end

        it 'can create a new service in the other project as expected' do
          expect_create_service other_project
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot create a new service in the project - returning 403 Forbidden' do
          post :create, params: { project_id: project.friendly_id }
          expect(response).to have_http_status(403)
        end

        it 'cannot create a new service in the other project - returning 403 Forbidden' do
          post :create, params: { project_id: other_project.friendly_id }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        service: {
          name: 'new name'
        }
      }
    end

    before do
      @service = create :service, name: 'name', project: project
      @other_service = create :service, name: 'other_name', project: other_project
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :update, params: { project_id: project.friendly_id, id: @service.id }.merge(put_data)
      end
    end

    it_behaves_like 'authenticated' do

      def expect_update_service project, service
        expect(Service.count).to eq 2
        expect(Audit.count).to eq 0
        put :update, params: { project_id: project.friendly_id, id: service.id }.merge(put_data)
        expect(response).to be_success
        expect(Service.count).to eq 2
        updated_service = Service.find(service.id)
        expect(updated_service.project).to eq project
        expect(updated_service.name).to eq put_data[:service][:name]
        expect(updated_service.description).to eq service.description
        expect(json_response).to include(
          'id' => service.id,
          'name' => put_data[:service][:name],
          'description' => service.description
        )
        expect(Audit.count).to be 1
        audit = Audit.first
        expect(audit.action).to eq 'update'
        expect(audit.associated).to eq project
        expect(audit.auditable).to eq service
        expect(audit.user).to eq current_user
      end

      it_behaves_like 'a hub admin' do

        it 'can update a service in the project as expected' do
          expect_update_service project, @service
        end

        it 'can update a service in the other project as expected' do
          expect_update_service other_project, @other_service
        end

        it 'should return a 404 for incorrect matching of project and service' do
          put :update, params: { project_id: other_project.friendly_id, id: @service.id }.merge(put_data)
          expect(response).to have_http_status(404)
        end

      end

      context 'not a hub admin but is an admin of the project' do

        before do
          create :project_membership_as_admin, project: project, user: current_user
        end

        it 'can update a service in the project as expected' do
          expect_update_service project, @service
        end

        it 'cannot update a service in the other project - returning 403 Forbidden' do
          put :update, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot update a service in the project - returning 403 Forbidden' do
          put :update, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'cannot update a service in the other project - returning 403 Forbidden' do
          put :update, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub admin but is an admin of the other project' do

        before do
          create :project_membership_as_admin, project: other_project, user: current_user
        end

        it 'cannot update a service in the project - returning 403 Forbidden' do
          put :update, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'can update a service in the other project as expected' do
          expect_update_service other_project, @other_service
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot update a service in the project - returning 403 Forbidden' do
          put :update, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'cannot update a service in the other project - returning 403 Forbidden' do
          put :update, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @service = create :service, project: project
      @other_service = create :service, project: other_project
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { project_id: project.friendly_id, id: @service.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_destroy_service project, service
        expect(Service.exists?(service.id)).to be true
        expect(Audit.count).to eq 0
        delete :destroy, params: { project_id: project.friendly_id, id: service.id }
        expect(response).to be_success
        expect(Service.exists?(service.id)).to be false
        expect(Audit.count).to eq 1
        audit = Audit.first
        expect(audit.action).to eq 'destroy'
        expect(audit.auditable_type).to eq Service.name
        expect(audit.auditable_id).to eq service.id
        expect(audit.user.id).to eq current_user_id
      end

      it_behaves_like 'a hub admin' do

        it 'can delete a service in the project as expected' do
          expect_destroy_service project, @service
        end

        it 'can delete a service in the other project as expected' do
          expect_destroy_service other_project, @other_service
        end

        it 'should return a 404 for incorrect matching of project and service' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @service.id }
          expect(response).to have_http_status(404)
        end

      end

      context 'not a hub admin but is an admin of the project' do

        before do
          create :project_membership_as_admin, project: project, user: current_user
        end

        it 'can delete a service in the project as expected' do
          expect_destroy_service project, @service
        end

        it 'cannot delete a service in the other project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot delete a service in the project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'cannot delete a service in the other project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub admin but is an admin of the other project' do

        before do
          create :project_membership_as_admin, project: other_project, user: current_user
        end

        it 'cannot delete a service in the project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'can delete a service in the other project as expected' do
          expect_destroy_service other_project, @other_service
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot delete a service in the project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'cannot delete a service in the other project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

  describe 'GET #kubernetes_groups' do
    before do
      @service = create :service, project: project
      @other_service = create :service, project: other_project

      @service_group_namespace_user_not_privileged = create :kubernetes_group, :for_namespace, :for_user, :not_privileged, allocate_to: @service
      @service_group_namespace_user_privileged = create :kubernetes_group, :for_namespace, :for_user, :privileged, allocate_to: @service
      @service_group_clusterwide_user_not_privileged = create :kubernetes_group, :for_clusterwide, :for_user, :not_privileged, allocate_to: @service
      @service_group_clusterwide_user_privileged = create :kubernetes_group, :for_clusterwide, :for_user, :privileged, allocate_to: @service
      @service_group_namespace_robot_not_privileged = create :kubernetes_group, :for_namespace, :for_robot, :not_privileged, allocate_to: @service
      @service_group_namespace_robot_privileged = create :kubernetes_group, :for_namespace, :for_robot, :privileged, allocate_to: @service

      @other_service_group_namespace_user_not_privileged = create :kubernetes_group, :for_namespace, :for_user, :not_privileged, allocate_to: @other_service
      @other_service_group_namespace_user_privileged = create :kubernetes_group, :for_namespace, :for_user, :privileged, allocate_to: @other_service

      # Unallocated groups
      create :kubernetes_group, :for_namespace, :for_user, :not_privileged
      create :kubernetes_group, :for_namespace, :for_user, :privileged
      create :kubernetes_group, :for_clusterwide, :for_user, :not_privileged
      create :kubernetes_group, :for_clusterwide, :for_user, :privileged
      create :kubernetes_group, :for_namespace, :for_robot, :not_privileged
    end

    let :service_user_groups do
      [
        @service_group_namespace_user_not_privileged,
        @service_group_namespace_user_privileged,
        @service_group_clusterwide_user_not_privileged,
        @service_group_clusterwide_user_privileged
      ].sort_by(&:name)
    end

    let :service_robot_groups do
      [
        @service_group_namespace_robot_not_privileged,
        @service_group_namespace_robot_privileged
      ]
    end

    let :service_all_groups do
      (service_user_groups + service_robot_groups).sort_by(&:name)
    end

    let :other_service_user_groups do
      [
        @other_service_group_namespace_user_not_privileged,
        @other_service_group_namespace_user_privileged
      ]
    end

    let :other_service_robot_groups do
      [ ]
    end

    let :other_service_all_groups do
      (other_service_user_groups + other_service_robot_groups).sort_by(&:name)
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :kubernetes_groups, params: { project_id: project.friendly_id, id: @service.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_groups project, service, target, groups
        params = { project_id: project.friendly_id, id: service.id }
        params[:target] = target if target
        get :kubernetes_groups, params: params
        expect(response).to be_success
        expect(pluck_from_json_response('name')).to match_array groups.map(&:name)
      end

      it_behaves_like 'a hub admin' do

        context 'no target specified' do
          it 'can fetch groups for service in the project as expected' do
            expect_groups project, @service, nil, service_all_groups
          end

          it 'can fetch groups for service in the other project as expected' do
            expect_groups other_project, @other_service, nil, other_service_all_groups
          end
        end

        context 'target=user' do
          it 'can fetch groups for service in the project as expected' do
            expect_groups project, @service, 'user', service_user_groups
          end

          it 'can fetch groups for service in the other project as expected' do
            expect_groups other_project, @other_service, 'user', other_service_user_groups
          end
        end

        context 'target=robot' do
          it 'can fetch groups for service in the project as expected' do
            expect_groups project, @service, 'robot', service_robot_groups
          end

          it 'can fetch groups for service in the other project as expected' do
            expect_groups other_project, @other_service, 'robot', other_service_robot_groups
          end
        end

        it 'should return a 404 for incorrect matching of project and service' do
          get :kubernetes_groups, params: { project_id: other_project.friendly_id, id: @service.id }
          expect(response).to have_http_status(404)
        end

        it 'should return a 400 error for an invalid target' do
          get :kubernetes_groups, params: { project_id: project.id, id: @service.id, target: 'invalid' }
          expect(response).to have_http_status(400)
        end

      end

      # NOTE: we don't need to repeat the target filtering specs anymore

      context 'not a hub admin but is an admin of the project' do

        before do
          create :project_membership_as_admin, project: project, user: current_user
        end

        it 'can fetch groups for service in the project as expected' do
          expect_groups project, @service, nil, service_all_groups
        end

        it 'cannot fetch groups for service in the other project - returning 403 Forbidden' do
          get :kubernetes_groups, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'can fetch groups for service in the project as expected' do
          expect_groups project, @service, nil, service_all_groups
        end

        it 'cannot fetch groups for service in the other project - returning 403 Forbidden' do
          get :kubernetes_groups, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub admin but is an admin of the other project' do

        before do
          create :project_membership_as_admin, project: other_project, user: current_user
        end

        it 'cannot fetch groups for service in the project - returning 403 Forbidden' do
          get :kubernetes_groups, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'can fetch groups for service in the other project as expected' do
          expect_groups other_project, @other_service, nil, other_service_all_groups
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot fetch groups for service in the project - returning 403 Forbidden' do
          get :kubernetes_groups, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'can fetch groups for service in the other project as expected' do
          expect_groups other_project, @other_service, nil, other_service_all_groups
        end

      end

    end
  end

  describe 'GET #kubernetes_robot_tokens' do
    before do
      @service = create :service, project: project
      @other_service = create :service, project: other_project
      @tokens = create_list :robot_kubernetes_token, 2, tokenable: @service
      @other_tokens = create_list :robot_kubernetes_token, 3, tokenable: @other_service

      # Create some random other tokens so we have a pool of tokens to query from
      create :user_kubernetes_token
      create :robot_kubernetes_token
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :kubernetes_robot_tokens, params: { project_id: project.friendly_id, id: @service.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_tokens project, service, tokens
        get :kubernetes_robot_tokens, params: { project_id: project.friendly_id, id: service.id }
        expect(response).to be_success
        expect(pluck_from_json_response('id')).to match_array tokens.map(&:id)
        expect(pluck_from_json_response('obfuscated_token')).to match_array tokens.map(&:obfuscated_token)
        expect(pluck_from_json_response('token')).to match_array tokens.map(&:decrypted_token)
      end

      it_behaves_like 'a hub admin' do

        it 'can fetch robot tokens for service in the project as expected' do
          expect_tokens project, @service, @tokens
        end

        it 'can fetch robot tokens for service in the other project as expected' do
          expect_tokens other_project, @other_service, @other_tokens
        end

        it 'should return a 404 for incorrect matching of project and service' do
          get :kubernetes_robot_tokens, params: { project_id: other_project.friendly_id, id: @service.id }
          expect(response).to have_http_status(404)
        end

      end

      context 'not a hub admin but is an admin of the project' do

        before do
          create :project_membership_as_admin, project: project, user: current_user
        end

        it 'can fetch robot tokens for service in the project as expected' do
          expect_tokens project, @service, @tokens
        end

        it 'cannot fetch robot tokens for service in the other project - returning 403 Forbidden' do
          get :kubernetes_robot_tokens, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot fetch robot tokens for service in the other project - returning 403 Forbidden' do
          get :kubernetes_robot_tokens, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub admin but is an admin of the other project' do

        before do
          create :project_membership_as_admin, project: other_project, user: current_user
        end

        it 'cannot fetch robot tokens for service in the project - returning 403 Forbidden' do
          get :kubernetes_robot_tokens, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'can fetch robot tokens for service in the other project as expected' do
          expect_tokens other_project, @other_service, @other_tokens
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot fetch robot tokens for service in the project - returning 403 Forbidden' do
          get :kubernetes_robot_tokens, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

  describe 'GET #show_kubernetes_robot_token' do
    before do
      @service = create :service, project: project
      @other_service = create :service, project: other_project
      @token = create :robot_kubernetes_token, tokenable: @service
      @other_token = create :robot_kubernetes_token, tokenable: @other_service
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show_kubernetes_robot_token, params: { project_id: project.friendly_id, id: @service.id, token_id: @token.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_token project, service, token, is_admin: false
        get :show_kubernetes_robot_token, params: { project_id: project.friendly_id, id: service.id, token_id: token.id }
        expect(response).to be_success

        cluster = {
          'id' => token.cluster.friendly_id,
          'aliases' => token.cluster.aliases,
          'name' => token.cluster.name,
          'description' => token.cluster.description,
          'api_url' => token.cluster.api_url,
          'ca_cert_encoded' => token.cluster.ca_cert_encoded
        }
        cluster['aws_account_id'] = token.cluster.aws_account_id if is_admin
        cluster['aws_region'] = token.cluster.aws_region if is_admin
        cluster['costs_bucket'] = token.cluster.costs_bucket if is_admin
        cluster['skip_sync'] = token.cluster.skip_sync if is_admin

        expect(json_response).to eq({
          'id' => token.id,
          'kind' => 'robot',
          'obfuscated_token' => token.obfuscated_token,
          'token' => token.decrypted_token,
          'name' => token.name,
          'uid' => token.uid,
          'groups' => token.groups,
          'cluster' => cluster,
          'description' => token.description,
          'service' => {
            'id' => service.id,
            'name' => service.name,
            'description' => service.description,
            'project'=> {
              'id' => project.friendly_id,
              'shortname' => project.shortname,
              'name' => project.name
            }
          },
          'project'=> {
            'id' => project.friendly_id,
            'shortname' => project.shortname,
            'name' => project.name
          }
        })
      end

      it_behaves_like 'a hub admin' do

        it 'can fetch a robot token for the service in the project as expected' do
          expect_token project, @service, @token, is_admin: true
        end

        it 'can fetch a robot token for the service in the other project as expected' do
          expect_token other_project, @other_service, @other_token, is_admin: true
        end

        it 'should return a 404 for a non-existent token' do
          get :show_kubernetes_robot_token, params: { project_id: other_project.friendly_id, id: @service.id, token_id: 'non-existent' }
          expect(response).to have_http_status(404)
        end

        it 'should return a 404 for incorrect matching of project and service' do
          get :show_kubernetes_robot_token, params: { project_id: other_project.friendly_id, id: @service.id, token_id: @token.id }
          expect(response).to have_http_status(404)
        end

        it 'should return a 404 for incorrect matching of token to project and service' do
          get :show_kubernetes_robot_token, params: { project_id: project.friendly_id, id: @service.id, token_id: @other_token.id }
          expect(response).to have_http_status(404)
        end

      end

      context 'not a hub admin but is an admin of the project' do

        before do
          create :project_membership_as_admin, project: project, user: current_user
        end

        it 'can fetch a robot token for the service in the project as expected' do
          expect_token project, @service, @token
        end

        it 'cannot fetch a robot token for the service in the other project - returning 403 Forbidden' do
          get :show_kubernetes_robot_token, params: { project_id: other_project.friendly_id, id: @other_service.id, token_id: @other_token.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot fetch a robot token for the service in the other project - returning 403 Forbidden' do
          get :show_kubernetes_robot_token, params: { project_id: other_project.friendly_id, id: @other_service.id, token_id: @other_token.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub admin but is an admin of the other project' do

        before do
          create :project_membership_as_admin, project: other_project, user: current_user
        end

        it 'cannot fetch a robot token for the service in the project - returning 403 Forbidden' do
          get :show_kubernetes_robot_token, params: { project_id: project.friendly_id, id: @service.id, token_id: @token.id }
          expect(response).to have_http_status(403)
        end

        it 'can fetch a robot token for the service in the other project as expected' do
          expect_token other_project, @other_service, @other_token
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot fetch a robot token for the service in the project - returning 403 Forbidden' do
          get :show_kubernetes_robot_token, params: { project_id: project.friendly_id, id: @service.id, token_id: @token.id }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

  describe 'POST #create_kubernetes_robot_token' do
    before do
      @service = create :service, project: project
      @other_service = create :service, project: other_project

      @cluster = create :kubernetes_cluster, allocate_to: [ project, other_project ]

      @robot_group_1 = create :kubernetes_group, :not_privileged, :for_robot, allocate_to: [ @service, @other_service ]
      @robot_group_2 = create :kubernetes_group, :not_privileged, :for_robot, allocate_to: [ @service, @other_service ]
    end

    let :post_data do
      {
        robot_token: {
          cluster_name: @cluster.name,
          groups: [ @robot_group_1.name, @robot_group_2.name ],
          name: 'token',
          description: 'important token'
        }
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :create_kubernetes_robot_token, params: post_data.merge({ project_id: project.friendly_id, id: @service.id })
      end
    end

    it_behaves_like 'authenticated' do

      def expect_create project, service
        expect(KubernetesToken.count).to eq 0
        expect(Audit.count).to eq 0
        post :create_kubernetes_robot_token, params: post_data.merge({ project_id: project.friendly_id, id: service.id })
        expect(response).to be_success
        expect(KubernetesToken.count).to eq 1
        token = KubernetesToken.first
        expect(json_response).to include({
          'id' => token.id,
          'kind' => 'robot',
          'name' => post_data[:robot_token][:name],
          'obfuscated_token' => token.obfuscated_token,
          'token' => token.decrypted_token,
          'uid' => token.uid,
          'groups' => post_data[:robot_token][:groups],
          'cluster' => include({
            'name' => post_data[:robot_token][:cluster_name]
          }),
          'description' => post_data[:robot_token][:description],
          'service' => {
            'id' => service.id,
            'name' => service.name,
            'description' => service.description,
            'project'=> {
              'id' => project.friendly_id,
              'shortname' => project.shortname,
              'name' => project.name
            }
          },
          'project'=> {
            'id' => project.friendly_id,
            'shortname' => project.shortname,
            'name' => project.name
          }
        })

        expect(Audit.count).to eq 1
        audit = Audit.first
        expect(audit.action).to eq 'create'
        expect(audit.auditable).to eq token
        expect(audit.associated).to eq service
        expect(audit.user).to eq current_user
      end

      it_behaves_like 'a hub admin' do

        it 'can create a robot token for the service in the project as expected' do
          expect_create project, @service
        end

        it 'can create a robot token for the service in the other project as expected' do
          expect_create other_project, @other_service
        end

        it 'should return a 404 for incorrect matching of project and service' do
          post :create_kubernetes_robot_token, params: post_data.merge({ project_id: other_project.friendly_id, id: @service.id })
          expect(response).to have_http_status(404)
          expect(KubernetesToken.count).to eq 0
        end

        it 'should return a 422 for a cluster that hasn\'t been allocated to the project' do
          unallocated_cluster = create :kubernetes_cluster
          params = {
            project_id: project.friendly_id,
            id: @service.id,
            robot_token: post_data.merge({ cluster_name: unallocated_cluster.name })
          }
          post :create_kubernetes_robot_token, params: params
          expect(response).to have_http_status(422)
          expect(KubernetesToken.count).to eq 0
        end

      end

      context 'not a hub admin but is an admin of the project' do

        before do
          create :project_membership_as_admin, project: project, user: current_user
        end

        it 'can create a robot token for the service in the project as expected' do
          expect_create project, @service
        end

        it 'cannot create a robot token for the service in the other project - returning 403 Forbidden' do
          post :create_kubernetes_robot_token, params: post_data.merge({ project_id: other_project.friendly_id, id: @other_service.id })
          expect(response).to have_http_status(403)
          expect(KubernetesToken.count).to eq 0
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot create a robot token for the service in the project - returning 403 Forbidden' do
          post :create_kubernetes_robot_token, params: post_data.merge({ project_id: project.friendly_id, id: @service.id })
          expect(response).to have_http_status(403)
          expect(KubernetesToken.count).to eq 0
        end

        it 'cannot create a robot token for the service in the other project - returning 403 Forbidden' do
          post :create_kubernetes_robot_token, params: post_data.merge({ project_id: other_project.friendly_id, id: @other_service.id })
          expect(response).to have_http_status(403)
          expect(KubernetesToken.count).to eq 0
        end

      end

      context 'not a hub admin but is an admin of the other project' do

        before do
          create :project_membership_as_admin, project: other_project, user: current_user
        end

        it 'cannot create a robot token for the service in the project - returning 403 Forbidden' do
          post :create_kubernetes_robot_token, params: post_data.merge({ project_id: project.friendly_id, id: @service.id })
          expect(response).to have_http_status(403)
          expect(KubernetesToken.count).to eq 0
        end

        it 'can create a robot token for the service in the other project as expected' do
          expect_create other_project, @other_service
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot create a robot token for the service in the project - returning 403 Forbidden' do
          post :create_kubernetes_robot_token, params: post_data.merge({ project_id: project.friendly_id, id: @service.id })
          expect(response).to have_http_status(403)
          expect(KubernetesToken.count).to eq 0
        end

        it 'cannot create a robot token for the service in the other project - returning 403 Forbidden' do
          post :create_kubernetes_robot_token, params: post_data.merge({ project_id: other_project.friendly_id, id: @other_service.id })
          expect(response).to have_http_status(403)
          expect(KubernetesToken.count).to eq 0
        end

      end

    end
  end

  describe 'PATCH #update_kubernetes_robot_token' do
    before do
      @service = create :service, project: project
      @other_service = create :service, project: other_project
      @token = create :robot_kubernetes_token, tokenable: @service
      @other_token = create :robot_kubernetes_token, tokenable: @other_service

      @robot_group_1 = create :kubernetes_group, :not_privileged, :for_robot, allocate_to: [ @service, @other_service ]
      @robot_group_2 = create :kubernetes_group, :not_privileged, :for_robot, allocate_to: [ @service, @other_service ]
    end

    let :patch_data do
      {
        robot_token: {
          groups: [ @robot_group_1.name, @robot_group_2.name ],
          description: 'new description'
        }
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: project.friendly_id, id: @service.id, token_id: @token.id })
      end
    end

    it_behaves_like 'authenticated' do

      def expect_update project, service, token, is_admin: false
        expect(Audit.count).to eq 0
        patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: project.friendly_id, id: service.id, token_id: token.id })
        expect(response).to be_success

        cluster = {
          'id' => token.cluster.friendly_id,
          'aliases' => token.cluster.aliases,
          'name' => token.cluster.name,
          'description' => token.cluster.description,
          'api_url' => token.cluster.api_url,
          'ca_cert_encoded' => token.cluster.ca_cert_encoded
        }
        cluster['aws_account_id'] = token.cluster.aws_account_id if is_admin
        cluster['aws_region'] = token.cluster.aws_region if is_admin
        cluster['costs_bucket'] = token.cluster.costs_bucket if is_admin
        cluster['skip_sync'] = token.cluster.skip_sync if is_admin

        expect(json_response).to include({
          'id' => token.id,
          'kind' => 'robot',
          'obfuscated_token' => token.obfuscated_token,
          'token' => token.decrypted_token,
          'name' => token.name,
          'uid' => token.uid,
          'groups' => patch_data[:robot_token][:groups],
          'cluster' => cluster,
          'description' => patch_data[:robot_token][:description],
          'service' => {
            'id' => service.id,
            'name' => service.name,
            'description' => service.description,
            'project'=> {
              'id' => project.friendly_id,
              'shortname' => project.shortname,
              'name' => project.name
            }
          }
        })

        expect(Audit.count).to eq 1
        audit = Audit.first
        expect(audit.action).to eq 'update'
        expect(audit.auditable).to eq token
        expect(audit.associated).to eq service
        expect(audit.user).to eq current_user
      end

      it_behaves_like 'a hub admin' do

        it 'can update a robot token for the service in the project as expected' do
          expect_update project, @service, @token, is_admin: true
        end

        it 'can update a robot token for the service in the other project as expected' do
          expect_update other_project, @other_service, @other_token, is_admin: true
        end

        it 'should return a 404 for a non-existent token' do
          patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: other_project.friendly_id, id: @service.id, token_id: 'non-existent' })
          expect(response).to have_http_status(404)
        end

        it 'should return a 404 for incorrect matching of project and service' do
          patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: other_project.friendly_id, id: @service.id, token_id: @token.id })
          expect(response).to have_http_status(404)
        end

        it 'should return a 404 for incorrect matching of token to project and service' do
          patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: project.friendly_id, id: @service.id, token_id: @other_token.id })
          expect(response).to have_http_status(404)
        end

      end

      context 'not a hub admin but is an admin of the project' do

        before do
          create :project_membership_as_admin, project: project, user: current_user
        end

        it 'can update a robot token for the service in the project as expected' do
          expect_update project, @service, @token
        end

        it 'cannot update a robot token for the service in the other project - returning 403 Forbidden' do
          patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: other_project.friendly_id, id: @other_service.id, token_id: @other_token })
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot update a robot token for the service in the project - returning 403 Forbidden' do
          patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: project.friendly_id, id: @service.id, token_id: @token })
          expect(response).to have_http_status(403)
        end

        it 'cannot update a robot token for the service in the other project - returning 403 Forbidden' do
          patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: other_project.friendly_id, id: @other_service.id, token_id: @other_token })
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub admin but is an admin of the other project' do

        before do
          create :project_membership_as_admin, project: other_project, user: current_user
        end

        it 'cannot update a robot token for the service in the project - returning 403 Forbidden' do
          patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: project.friendly_id, id: @service.id, token_id: @token })
          expect(response).to have_http_status(403)
        end

        it 'can update a robot token for the service in the other project as expected' do
          expect_update other_project, @other_service, @other_token
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot update a robot token for the service in the project - returning 403 Forbidden' do
          patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: project.friendly_id, id: @service.id, token_id: @token.id })
          expect(response).to have_http_status(403)
        end

        it 'cannot update a robot token for the service in the other project - returning 403 Forbidden' do
          patch :update_kubernetes_robot_token, params: patch_data.merge({ project_id: other_project.friendly_id, id: @other_service.id, token_id: @other_token.id })
          expect(response).to have_http_status(403)
        end

      end

    end
  end

  describe 'DELETE #destroy_kubernetes_robot_token' do
    before do
      @service = create :service, project: project
      @other_service = create :service, project: other_project
      @token = create :robot_kubernetes_token, tokenable: @service
      @other_token = create :robot_kubernetes_token, tokenable: @other_service
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy_kubernetes_robot_token, params: { project_id: project.friendly_id, id: @service.id, token_id: @token.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_destroy project, service, token
        delete :destroy_kubernetes_robot_token, params: { project_id: project.friendly_id, id: service.id, token_id: token.id }
        expect(response).to be_success
        expect(KubernetesToken.exists?(token.id)).to be false

        expect(Audit.count).to eq 1
        audit = Audit.first
        expect(audit.action).to eq 'destroy'
        expect(audit.auditable_id).to eq token.id
        expect(audit.associated).to eq service
        expect(audit.user).to eq current_user
      end

      it_behaves_like 'a hub admin' do

        it 'can delete a robot token for the service in the project as expected' do
          expect_destroy project, @service, @token
        end

        it 'can delete a robot token for the service in the other project as expected' do
          expect_destroy other_project, @other_service, @other_token
        end

        it 'should return a 404 for a non-existent token' do
          delete :destroy_kubernetes_robot_token, params: { project_id: other_project.friendly_id, id: @service.id, token_id: 'non-existent' }
          expect(response).to have_http_status(404)
        end

        it 'should return a 404 for incorrect matching of project and service' do
          delete :destroy_kubernetes_robot_token, params: { project_id: other_project.friendly_id, id: @service.id, token_id: @token.id }
          expect(response).to have_http_status(404)
        end

        it 'should return a 404 for incorrect matching of token to project and service' do
          delete :destroy_kubernetes_robot_token, params: { project_id: project.friendly_id, id: @service.id, token_id: @other_token.id }
          expect(response).to have_http_status(404)
        end

      end

      context 'not a hub admin but is an admin of the project' do

        before do
          create :project_membership_as_admin, project: project, user: current_user
        end

        it 'can delete a robot token for the service in the project as expected' do
          expect_destroy project, @service, @token
        end

        it 'cannot delete a robot token for the service in the other project - returning 403 Forbidden' do
          delete :destroy_kubernetes_robot_token, params: { project_id: other_project.friendly_id, id: @other_service.id, token_id: @other_token }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub or project admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot delete a robot token for the service in the project - returning 403 Forbidden' do
          delete :destroy_kubernetes_robot_token, params: { project_id: project.friendly_id, id: @service.id, token_id: @token }
          expect(response).to have_http_status(403)
        end

        it 'cannot delete a robot token for the service in the other project - returning 403 Forbidden' do
          delete :destroy_kubernetes_robot_token, params: { project_id: other_project.friendly_id, id: @other_service.id, token_id: @other_token }
          expect(response).to have_http_status(403)
        end

      end

      context 'not a hub admin but is an admin of the other project' do

        before do
          create :project_membership_as_admin, project: other_project, user: current_user
        end

        it 'cannot delete a robot token for the service in the project - returning 403 Forbidden' do
          delete :destroy_kubernetes_robot_token, params: { project_id: project.friendly_id, id: @service.id, token_id: @token }
          expect(response).to have_http_status(403)
        end

        it 'can delete a robot token for the service in the other project as expected' do
          expect_destroy other_project, @other_service, @other_token
        end

      end

      context 'not a hub or other project admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot delete a robot token for the service in the project - returning 403 Forbidden' do
          delete :destroy_kubernetes_robot_token, params: { project_id: project.friendly_id, id: @service.id, token_id: @token.id }
          expect(response).to have_http_status(403)
        end

        it 'cannot delete a robot token for the service in the other project - returning 403 Forbidden' do
          delete :destroy_kubernetes_robot_token, params: { project_id: other_project.friendly_id, id: @other_service.id, token_id: @other_token.id }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

end
