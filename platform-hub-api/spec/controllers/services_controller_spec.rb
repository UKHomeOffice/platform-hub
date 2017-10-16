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

      it_behaves_like 'an admin' do

        it 'should return a list of all services for the project' do
          expect_project_services
        end

        it 'should return a list of all services for the other project' do
          expect_other_project_services
        end

      end

      context 'not an admin but is a member of the project' do

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

      context 'not an admin but is a member of other project' do

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
        expect(json_response).to include(
          'id' => @service.id,
          'name' => @service.name,
          'description' => @service.description
        )
      end

      def expect_other_service
        get :show, params: { project_id: other_project.friendly_id, id: @other_service.id }
        expect(response).to be_success
        expect(json_response).to include(
          'id' => @other_service.id,
          'name' => @other_service.name,
          'description' => @other_service.description
        )
      end

      context 'for a non-existent service' do
        it 'should return a 404' do
          get :show, params: { project_id: project.friendly_id, id: 'nonexistent-service' }
          expect(response).to have_http_status(404)
        end
      end

      it_behaves_like 'an admin' do

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

      context 'not an admin but is a member of the project' do

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

      context 'not an admin but is a member of other project' do

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

      it_behaves_like 'an admin' do

        it 'can create a new service in the project as expected' do
          expect_create_service project
        end

        it 'can create a new service in the other project as expected' do
          expect_create_service other_project
        end

      end

      context 'not an admin but is manager of the project' do

        before do
          create :project_membership_as_manager, project: project, user: current_user
        end

        it 'can create a new service in the project as expected' do
          expect_create_service project
        end

        it 'cannot create a new service in the other project - returning 403 Forbidden' do
          post :create, params: { project_id: other_project.friendly_id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not an admin but is a member of the project' do

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

      context 'not an admin but is manager of the other project' do

        before do
          create :project_membership_as_manager, project: other_project, user: current_user
        end

        it 'cannot create a new service in the project - returning 403 Forbidden' do
          post :create, params: { project_id: project.friendly_id }
          expect(response).to have_http_status(403)
        end

        it 'can create a new service in the other project as expected' do
          expect_create_service other_project
        end

      end

      context 'not an admin but is a member of other project' do

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

      it_behaves_like 'an admin' do

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

      context 'not an admin but is manager of the project' do

        before do
          create :project_membership_as_manager, project: project, user: current_user
        end

        it 'can update a service in the project as expected' do
          expect_update_service project, @service
        end

        it 'cannot update a service in the other project - returning 403 Forbidden' do
          put :update, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not an admin but is a member of the project' do

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

      context 'not an admin but is manager of the other project' do

        before do
          create :project_membership_as_manager, project: other_project, user: current_user
        end

        it 'cannot update a service in the project - returning 403 Forbidden' do
          put :update, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'can update a new service in the other project as expected' do
          expect_update_service other_project, @other_service
        end

      end

      context 'not an admin but is a member of other project' do

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
        expect(audit.user.id).to eq current_user_id
      end

      it_behaves_like 'an admin' do

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

      context 'not an admin but is manager of the project' do

        before do
          create :project_membership_as_manager, project: project, user: current_user
        end

        it 'can delete a service in the project as expected' do
          expect_destroy_service project, @service
        end

        it 'cannot update a service in the other project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not an admin but is a member of the project' do

        before do
          create :project_membership, project: project, user: current_user
        end

        it 'cannot update a service in the project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'cannot update a service in the other project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

      context 'not an admin but is manager of the other project' do

        before do
          create :project_membership_as_manager, project: other_project, user: current_user
        end

        it 'cannot update a service in the project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'can delete a new service in the other project as expected' do
          expect_destroy_service other_project, @other_service
        end

      end

      context 'not an admin but is a member of other project' do

        before do
          create :project_membership, project: other_project, user: current_user
        end

        it 'cannot update a service in the project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: project.friendly_id, id: @service.id }
          expect(response).to have_http_status(403)
        end

        it 'cannot update a service in the other project - returning 403 Forbidden' do
          delete :destroy, params: { project_id: other_project.friendly_id, id: @other_service.id }
          expect(response).to have_http_status(403)
        end

      end

    end
  end

end
