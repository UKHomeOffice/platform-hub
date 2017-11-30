require 'rails_helper'

RSpec.describe Kubernetes::NamespacesController, type: :controller do

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

        context 'when no kubernetes namespaces exist' do
          it 'returns an empty list' do
            get :index
            expect(response).to be_success
            expect(json_response).to be_empty
          end
        end

        context 'when kubernetes namespaces exist' do
          before do
            @namespaces = create_list :kubernetes_namespace, 3
          end

          let :total_namespaces do
            @namespaces.length
          end

          let :all_namespace_ids do
            @namespaces.map(&:id)
          end

          it 'returns all the existing kubernetes namespaces ordered by name descending' do
            get :index
            expect(response).to be_success
            expect(json_response.length).to eq total_namespaces
            expect(pluck_from_json_response('id')).to match_array all_namespace_ids
          end

          it 'returns namespaces by service' do
            namespace = @namespaces.last
            get :index, params: { service_id: namespace.service.id }
            expect(json_response.length).to eq 1
            expect(pluck_from_json_response('id')).to eq [namespace.id]
          end

          it 'returns namespaces by cluster' do
            namespace = @namespaces.last
            get :index, params: { cluster_name: namespace.cluster.id }
            expect(json_response.length).to eq 1
            expect(pluck_from_json_response('id')).to eq [namespace.id]
          end
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @namespace = create :kubernetes_namespace
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @namespace.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :show, params: { id: @namespace.id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'for a non-existent namespace' do
          it 'should return a 404' do
            get :show, params: { id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a namespace that exists' do
          it 'should return the specified namespace resource' do
            get :show, params: { id: @namespace.id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @namespace.id,
              'name' => @namespace.name,
              'description' => @namespace.description,
              'cluster' => {
                'id' => @namespace.cluster.friendly_id,
                'name' => @namespace.cluster.name,
                'description' => @namespace.cluster.description
              },
              'service' => {
                'id' => @namespace.service.id,
                'name' => @namespace.service.name,
                'description' => @namespace.service.description,
                'project'=> {
                  'id' => @namespace.service.project.friendly_id,
                  'shortname' => @namespace.service.project.shortname,
                  'name' => @namespace.service.project.name
                }
              }
            })
          end
        end

      end

    end
  end

  describe 'POST #create' do
    let(:service) { create :service }
    let(:cluster) { create :kubernetes_cluster, allocate_to: service.project }

    let :post_data do
      {
        namespace: {
          service_id: service.id,
          cluster_name: cluster.name,
          name: 'foobar',
          description: 'foobar desc'
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

        it 'creates a new namespace as expected' do
          expect(KubernetesNamespace.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(KubernetesNamespace.count).to eq 1
          namespace = KubernetesNamespace.first
          expect(json_response).to eq({
            'id' => namespace.id,
            'name' => post_data[:namespace][:name],
            'description' => post_data[:namespace][:description],
            'cluster' => {
              'id' => namespace.cluster.friendly_id,
              'name' => post_data[:namespace][:cluster_name],
              'description' => namespace.cluster.description
            },
            'service' => {
              'id' => post_data[:namespace][:service_id],
              'name' => namespace.service.name,
              'description' => namespace.service.description,
              'project'=> {
                'id' => namespace.service.project.friendly_id,
                'shortname' => namespace.service.project.shortname,
                'name' => namespace.service.project.name
              }
            }
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq namespace.id
          expect(audit.associated).to eq namespace.service
          expect(audit.user.id).to eq current_user_id
        end

        context 'with existing namespace' do
          before do
            @existing_namespace = create :kubernetes_namespace
          end

          it 'fails to create a new namespace with a name that\'s already taken for that cluster' do
            post_data_with_same_name_and_cluster = {
              namespace: post_data[:namespace].clone.tap do |h|
                h[:name] = @existing_namespace.name
                h[:cluster_name] = @existing_namespace.cluster.name
              end
            }
            expect(KubernetesNamespace.count).to eq 1
            expect(Audit.count).to eq 0
            post :create, params: post_data_with_same_name_and_cluster
            expect(response).to have_http_status(422)
            expect(json_response['error']['message']).not_to be_empty
            expect(KubernetesNamespace.count).to eq 1
            expect(Audit.count).to eq 0
          end
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @namespace.id,
        namespace: {
          description: 'different foobar description'
        }
      }
    end

    before do
      @namespace = create :kubernetes_namespace, description: 'foo'
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

        it 'updates the specified namespace' do
          expect(KubernetesNamespace.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_data
          expect(response).to be_success
          expect(KubernetesNamespace.count).to eq 1
          updated = KubernetesNamespace.first
          expect(updated.name).to eq @namespace.name
          expect(updated.description).to eq put_data[:namespace][:description]
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update'
          expect(audit.auditable.id).to eq @namespace.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @namespace = create :kubernetes_namespace
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @namespace.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          delete :destroy, params: { id: @namespace.id }
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should delete the specified namespace' do
          expect(KubernetesNamespace.exists?(@namespace.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @namespace.id }
          expect(response).to be_success
          expect(KubernetesNamespace.exists?(@namespace.id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.auditable_type).to eq KubernetesNamespace.name
          expect(audit.auditable_id).to eq @namespace.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

end
