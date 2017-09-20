require 'rails_helper'

RSpec.describe Kubernetes::ClustersController, type: :controller do

  let(:key) { 'clusters' }

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

        context 'when no kubernetes clusters exist' do
          it 'creates an empty kubernetes clusters under the hood and returns it' do
            expect(HashRecord.kubernetes.where(id: key).count).to eq 0
            get :index
            expect(response).to be_success
            expect(json_response).to eq([])
            expect(HashRecord.kubernetes.where(id: key).count).to eq 1
          end
        end

        context 'when kubernetes clusters already exist' do
          let :data do
            [
              { 'id' => 'foo', 'description' => 'Foo cluster' },
              { 'id' => 'bar', 'description' => 'Bar cluster' },
              { 'id' => 'baz', 'description' => 'Baz cluster' },
            ]
          end

          let :expected_data do
            [
              data[1],
              data[2],
              data[0]
            ]
          end

          before do
            @kubernetes_clusters = create :hash_record, id: key, scope: 'kubernetes', data: data
          end

          it 'returns the existing kubernetes clusters data' do
            get :index
            expect(response).to be_success
            expect(json_response).to eq expected_data
          end
        end

      end
    end
  end

  describe 'PATCH/PUT #create_or_update' do

    let(:id) { 'foo' }

    it_behaves_like 'unauthenticated not allowed' do
      before do
        put :create_or_update, params: { id: id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          put :create_or_update, params: { id: id }
        end
      end

      it_behaves_like 'an admin' do

        let :put_data do
          {
            description: 'description',
            s3_region: 's3_region',
            s3_bucket_name: 's3_bucket_name',
            s3_access_key_id: 's3_access_key_id',
            s3_secret_access_key: 's3_secret_access_key',
            object_key: 'object_key'
          }
        end

        it 'should call the Kubernetes::ClusterService to create or update the cluster config' do
          expect(Kubernetes::ClusterService).to receive(:create_or_update).with({
            id: id,
            description: put_data[:description],
            s3_region: put_data[:s3_region],
            s3_bucket_name: put_data[:s3_bucket_name],
            s3_access_key_id: put_data[:s3_access_key_id],
            s3_secret_access_key: put_data[:s3_secret_access_key],
            object_key: put_data[:object_key]
          })

          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'update_kubernetes_cluster',
            data: { id: id },
            comment: "Kubernetes cluster '#{id}' created or updated by #{current_user.email}"
          )

          put :create_or_update, params: {
            id: id,
            cluster: put_data
          }

          expect(response).to be_success
          expect(response).to have_http_status(204)
        end

      end

    end

  end

end
