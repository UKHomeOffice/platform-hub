require 'rails_helper'

RSpec.describe Kubernetes::ClustersController, type: :controller do

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

        context 'when no kubernetes clusters exist' do
          before do
            expect(KubernetesCluster).to receive(:order) { [] }
          end

          it 'returns an empty list' do
            get :index
            expect(response).to be_success
            expect(json_response).to eq([])
          end
        end

        context 'when kubernetes clusters already exist' do
          before do
            create(:kubernetes_cluster, name: :foo, description: 'Foo')
            create(:kubernetes_cluster, name: :bar, description: 'Bar')
            create(:kubernetes_cluster, name: :baz, description: 'Baz')
          end

          it 'returns the existing kubernetes clusters ordered by name descending' do
            get :index
            expect(response).to be_success
            expect(json_response[0]['name']).to eq 'bar'
            expect(json_response[1]['name']).to eq 'baz'
            expect(json_response[2]['name']).to eq 'foo'
          end
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @cluster = create :kubernetes_cluster
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @cluster.friendly_id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :show, params: { id: @cluster.friendly_id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'for a non-existent cluster' do
          it 'should return a 404' do
            get :show, params: { id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a cluster that exists' do
          it 'should return the specified cluster resource' do
            get :show, params: { id: @cluster.friendly_id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @cluster.friendly_id,
              'name' => @cluster.name,
              'description' => @cluster.description,
            })
          end
        end

      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      {
        cluster: {
          name: 'foobar',
          description: 'foobar desc',
          s3_region: 's3_region',
          s3_bucket_name: 's3_bucket_name',
          s3_access_key_id: 's3_access_key_id',
          s3_secret_access_key: 's3_secret_access_key',
          s3_object_key: 's3_object_key'
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

        it 'creates a new kubernetes cluster config as expected' do
          expect(KubernetesCluster.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(KubernetesCluster.count).to eq 1
          cluster = KubernetesCluster.first
          new_cluster_external_id = cluster.friendly_id
          new_cluster_internal_id = cluster.id
          expect(json_response).to eq({
            'id' => new_cluster_external_id,
            'name' => post_data[:cluster][:name],
            'description' => post_data[:cluster][:description],
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq new_cluster_internal_id
          expect(audit.user.id).to eq current_user_id
        end

        context 'with existing cluster' do
          before do
            @existing_cluster = create :kubernetes_cluster
          end

          it 'fails to create a new cluster with a name that\'s already taken' do
            post_data_with_same_name = {
              cluster: post_data[:cluster].clone.tap { |h| h[:name] = @existing_cluster.name }
            }
            expect(KubernetesCluster.count).to eq 1
            expect(Audit.count).to eq 0
            post :create, params: post_data_with_same_name
            expect(response).to have_http_status(422)
            expect(json_response['error']['message']).not_to be_empty
            expect(KubernetesCluster.count).to eq 1
            expect(Audit.count).to eq 0
          end
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @cluster.friendly_id,
        cluster: {
          s3_region: 'new_s3_region'
        }
      }
    end

    let :existing_description do
      'so much foobar'
    end

    before do
      @cluster = create :kubernetes_cluster, description: existing_description
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

        it 'updates the specified cluster' do
          expect(KubernetesCluster.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_data
          expect(response).to be_success
          expect(KubernetesCluster.count).to eq 1
          updated = KubernetesCluster.first
          expect(updated.name).to eq @cluster.name
          expect(updated.description).to eq existing_description
          expect(updated.s3_region).to eq put_data[:cluster][:s3_region]
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update'
          expect(audit.auditable.id).to eq @cluster.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'POST #allocate' do
    before do
      @cluster = create :kubernetes_cluster
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post :allocate, params: { id: @cluster.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :allocate, params: { id: @cluster.id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'for a non-existent project' do
          it 'should return a 404' do
            post :allocate, params: { id: @cluster.id, project_id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a project that exists' do
          let!(:project) { create :project }

          it 'allocates the cluster to the project' do
            expect(Allocation.count).to be 0
            expect(Audit.count).to eq 0
            post :allocate, params: { id: @cluster.id, project_id: project.friendly_id }
            expect(response).to be_success
            expect(Allocation.count).to be 1
            expect(Audit.count).to eq 1
            allocation = Allocation.first
            expect(allocation.allocatable).to eq @cluster
            expect(allocation.allocation_receivable).to eq project
            audit = Audit.first
            expect(audit.action).to eq 'create'
            expect(audit.auditable).to eq allocation
            expect(audit.associated).to eq project
            expect(audit.data).to eq({
              'allocatable_type' => @cluster.class.name,
              'allocatable_id' => @cluster.id,
              'allocatable_descriptor' => @cluster.name
            })
            expect(audit.user.id).to eq current_user_id
          end
        end

      end
    end
  end

  describe 'GET #allocations' do
    before do
      @cluster = create :kubernetes_cluster
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :allocations, params: { id: @cluster.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :allocations, params: { id: @cluster.id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'when no allocations exist' do
          it 'returns an empty list' do
            get :allocations, params: { id: @cluster.id }
            expect(response).to be_success
            expect(json_response).to be_empty
          end
        end

        context 'when allocations exist' do
          let!(:project_1) { create :project }
          let!(:project_2) { create :project }
          let!(:other_cluster) { create :kubernetes_cluster }

          before do
            @allocations = [
              create(:allocation, allocatable: @cluster, allocation_receivable: project_1),
              create(:allocation, allocatable: @cluster, allocation_receivable: project_2)
            ]
            create :allocation, allocatable: other_cluster, allocation_receivable: project_1
          end

          let :total_allocations do
            @allocations.length
          end

          let :all_allocation_ids do
            @allocations.map(&:id)
          end

          it 'returns the existing kubernetes allocations ordered by name descending' do
            get :allocations, params: { id: @cluster.id }
            expect(response).to be_success
            expect(json_response.length).to eq total_allocations
            expect(pluck_from_json_response('id')).to match_array all_allocation_ids
          end
        end

      end

    end
  end

end
