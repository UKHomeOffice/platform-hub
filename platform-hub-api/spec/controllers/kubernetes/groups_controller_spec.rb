require 'rails_helper'

RSpec.describe Kubernetes::GroupsController, type: :controller do

  include_context 'time helpers'

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :index
        end
      end

      it_behaves_like 'a hub admin' do

        context 'when no kubernetes groups exist' do
          it 'returns an empty list' do
            get :index
            expect(response).to be_success
            expect(json_response).to be_empty
          end
        end

        context 'when kubernetes groups exist' do
          before do
            @groups = create_list :kubernetes_group, 3
          end

          let :total_groups do
            @groups.length
          end

          let :all_group_ids do
            @groups.map(&:friendly_id)
          end

          it 'returns the existing kubernetes groups ordered by name descending' do
            get :index
            expect(response).to be_success
            expect(json_response.length).to eq total_groups
            expect(pluck_from_json_response('id')).to match_array all_group_ids
          end
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @group = create :kubernetes_group
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @group.friendly_id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :show, params: { id: @group.friendly_id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'for a non-existent group' do
          it 'should return a 404' do
            get :show, params: { id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a group that exists' do
          it 'should return the specified group resource' do
            get :show, params: { id: @group.friendly_id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @group.friendly_id,
              'name' => @group.name,
              'kind' => @group.kind,
              'target' => @group.target,
              'description' => @group.description,
              'is_privileged' => @group.is_privileged,
              'restricted_to_clusters' => @group.restricted_to_clusters
            })
          end
        end

      end

    end
  end

  describe 'POST #create' do
    let(:cluster1) { create :kubernetes_cluster }
    let(:cluster2) { create :kubernetes_cluster }

    let :post_data do
      {
        group: {
          name: 'foobar',
          kind: 'namespace',
          target: 'robot',
          description: 'foobar desc',
          is_privileged: true,
          restricted_to_clusters: [ cluster1.name, cluster2.name ]
        }
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :create, params: post_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :create, params: post_data
        end
      end

      it_behaves_like 'a hub admin' do

        it 'creates a new group as expected' do
          expect(KubernetesGroup.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(KubernetesGroup.count).to eq 1
          group = KubernetesGroup.first
          new_group_external_id = group.friendly_id
          new_group_internal_id = group.id
          expect(json_response).to eq({
            'id' => new_group_external_id,
            'name' => post_data[:group][:name],
            'kind' => post_data[:group][:kind],
            'target' => post_data[:group][:target],
            'description' => post_data[:group][:description],
            'is_privileged' => post_data[:group][:is_privileged],
            'restricted_to_clusters' => post_data[:group][:restricted_to_clusters]
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq new_group_internal_id
          expect(audit.user.id).to eq current_user_id
        end

        context 'with existing group' do
          before do
            @existing_group = create :kubernetes_group
          end

          it 'fails to create a new group with a name that\'s already taken' do
            post_data_with_same_name = {
              group: post_data[:group].clone.tap { |h| h[:name] = @existing_group.name }
            }
            expect(KubernetesGroup.count).to eq 1
            expect(Audit.count).to eq 0
            post :create, params: post_data_with_same_name
            expect(response).to have_http_status(422)
            expect(json_response['error']['message']).not_to be_empty
            expect(KubernetesGroup.count).to eq 1
            expect(Audit.count).to eq 0
          end
        end

      end

    end
  end

  describe 'PUT #update' do
    let(:cluster) { create :kubernetes_cluster }

    let :put_data do
      {
        id: @group.friendly_id,
        group: {
          kind: 'namespace',
          description: 'different foobar description',
          is_privileged: !@group.is_privileged,
          restricted_to_clusters: nil
        }
      }
    end

    before do
      @group = create :kubernetes_group, restricted_to_clusters: [ cluster.name ]
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :update, params: put_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          put :update, params: put_data
        end
      end

      it_behaves_like 'a hub admin' do

        it 'updates the specified group' do
          expect(KubernetesGroup.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_data
          expect(response).to be_success
          expect(KubernetesGroup.count).to eq 1
          updated = KubernetesGroup.first
          expect(updated.name).to eq @group.name
          expect(updated.kind).to eq put_data[:group][:kind]
          expect(updated.target).to eq @group.target
          expect(updated.description).to eq put_data[:group][:description]
          expect(updated.is_privileged).to eq put_data[:group][:is_privileged]
          expect(updated.restricted_to_clusters).to eq []
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update'
          expect(audit.auditable.id).to eq @group.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @group = create :kubernetes_group
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @group.friendly_id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          delete :destroy, params: { id: @group.friendly_id }
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should delete the specified group' do
          expect(KubernetesGroup.exists?(@group.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @group.friendly_id }
          expect(response).to be_success
          expect(KubernetesGroup.exists?(@group.id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.auditable_type).to eq KubernetesGroup.name
          expect(audit.auditable_id).to eq @group.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'POST #allocate' do
    before do
      @group = create :kubernetes_group
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post :allocate, params: { id: @group.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :allocate, params: { id: @group.id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'for a non-existent project' do
          it 'should return a 404' do
            post :allocate, params: { id: @group.id, project_id: 'unknown', service_id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a non-existent project service' do
          let!(:project) { create :project }

          it 'should return a 404' do
            post :allocate, params: { id: @group.id, project_id: project.friendly_id, service_id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a project and project service that exists' do
          let!(:project) { create :project }
          let!(:service) { create :service, project: project }

          def expect_allocate params, receivable
            expect(Allocation.count).to be 0
            expect(Audit.count).to eq 0
            post :allocate, params: params
            expect(response).to be_success
            expect(Allocation.count).to be 1
            expect(Audit.count).to eq 1
            allocation = Allocation.first
            expect(allocation.allocatable).to eq @group
            expect(allocation.allocation_receivable).to eq receivable
            audit = Audit.first
            expect(audit.action).to eq 'create'
            expect(audit.auditable).to eq allocation
            expect(audit.associated).to eq receivable
            expect(audit.data).to eq({
              'allocatable_type' => @group.class.name,
              'allocatable_id' => @group.id,
              'allocatable_descriptor' => @group.name
            })
            expect(audit.user.id).to eq current_user_id
          end

          context 'when only a project_id is specified' do
            it 'allocates the group to the project' do
              expect_allocate(
                { id: @group.id, project_id: project.friendly_id },
                project
              )
            end
          end

          context 'when both project_id and service_id are specified' do
            it 'allocates the group to the project service' do
              expect_allocate(
                { id: @group.id, project_id: project.friendly_id, service_id: service.id },
                service
              )
            end
          end
        end

      end
    end
  end

  describe 'GET #allocations' do
    before do
      @group = create :kubernetes_group
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :allocations, params: { id: @group.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :allocations, params: { id: @group.id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'when no allocations exist' do
          it 'returns an empty list' do
            get :allocations, params: { id: @group.id }
            expect(response).to be_success
            expect(json_response).to be_empty
          end
        end

        context 'when allocations exist' do
          let!(:service_1) { create :service }
          let!(:service_2) { create :service }
          let!(:other_group) { create :kubernetes_group }

          before do
            @allocations = [
              create(:allocation, allocatable: @group, allocation_receivable: service_1),
              create(:allocation, allocatable: @group, allocation_receivable: service_2)
            ]
            create :allocation, allocatable: other_group, allocation_receivable: service_1
          end

          let :total_allocations do
            @allocations.length
          end

          let :all_allocation_ids do
            @allocations.map(&:id)
          end

          it 'returns the existing kubernetes allocations ordered by name descending' do
            get :allocations, params: { id: @group.id }
            expect(response).to be_success
            expect(json_response.length).to eq total_allocations
            expect(pluck_from_json_response('id')).to match_array all_allocation_ids
          end
        end

      end

    end
  end

  describe 'GET #tokens' do
    before do
      @group = create :kubernetes_group, :for_robot, :not_privileged
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :tokens, params: { id: @group.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :tokens, params: { id: @group.id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'when no tokens exist' do
          it 'returns an empty list' do
            get :tokens, params: { id: @group.id }
            expect(response).to be_success
            expect(json_response).to be_empty
          end
        end

        context 'when tokens exist' do
          let!(:service_1) { create :service }
          let!(:service_2) { create :service }

          let!(:other_group) { create :kubernetes_group, :for_robot, :not_privileged }

          before do
            # Make sure groups are allocated so we can create tokens for them
            create(:allocation, allocatable: @group, allocation_receivable: service_1)
            create(:allocation, allocatable: @group, allocation_receivable: service_2)
            create(:allocation, allocatable: other_group, allocation_receivable: service_1)
            create(:allocation, allocatable: other_group, allocation_receivable: service_2)

            @tokens = [
              create(:robot_kubernetes_token, tokenable: service_1, groups: [@group.name]),
              create(:robot_kubernetes_token, tokenable: service_2, groups: [@group.name]),
              create(:robot_kubernetes_token, tokenable: service_2, groups: [@group.name, other_group.name]),
            ]
            create :robot_kubernetes_token, tokenable: service_1, groups: [other_group.name]
            create :robot_kubernetes_token, tokenable: service_1, groups: []
            create :robot_kubernetes_token
            create :user_kubernetes_token
          end

          let :total_tokens do
            @tokens.length
          end

          let :all_token_ids do
            @tokens.sort_by(&:updated_at).reverse.map(&:id)
          end

          it 'returns the existing kubernetes tokens ordered by last updated descending' do
            get :tokens, params: { id: @group.id }
            expect(response).to be_success
            expect(json_response.length).to eq total_tokens
            expect(pluck_from_json_response('id')).to match_array all_token_ids
          end
        end

      end

    end
  end

  describe 'GET #filters' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :filters
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :filters
        end
      end

      it_behaves_like 'a hub admin' do
        it 'returns filters available' do
          get :filters
          expect(response).to be_success
        end
      end

    end
  end

end
