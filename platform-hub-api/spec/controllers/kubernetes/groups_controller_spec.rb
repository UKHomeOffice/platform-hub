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

      context 'when no kubernetes groups exist' do
        it 'returns an empty list' do
          get :index
          expect(response).to be_success
          expect(json_response).to be_empty
        end
      end

      context 'when kubernetes groups already exist' do
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

  describe 'POST #create' do
    let :post_data do
      {
        group: {
          name: 'foobar',
          kind: 'namespace',
          target: 'robot',
          description: 'foobar desc',
          is_privileged: true,
          restricted_to_clusters: ['cluster1', 'cluster2']
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
      @group = create :kubernetes_group, restricted_to_clusters: [ 'foo' ]
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

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { id: @group.friendly_id }
        end
      end

      it_behaves_like 'an admin' do

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

  describe 'GET #privileged' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :privileged
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :privileged
        end
      end

      it_behaves_like 'an admin' do
        let!(:not_privileged_group) { create :kubernetes_group, is_privileged: false }
        let!(:privileged_group) { create :kubernetes_group, is_privileged: true }
        let!(:default_privileged_group) { create :kubernetes_group }

        it 'returns the list of privileged kubernetes groups' do
          get :privileged
          expect(response).to be_success
          expect(json_response).to eq([{
            'id' => privileged_group.friendly_id,
            'name' => privileged_group.name,
            'kind' => privileged_group.kind,
            'target' => privileged_group.target,
            'description' => privileged_group.description,
            'is_privileged' => privileged_group.is_privileged,
            'restricted_to_clusters' => privileged_group.restricted_to_clusters
          }])
        end

      end
    end
  end

end
