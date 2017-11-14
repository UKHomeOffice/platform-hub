require 'rails_helper'

RSpec.describe Kubernetes::SyncController, type: :controller do

  let(:cluster_name) { 'development' }

  describe 'POST #sync' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post :sync, params: { cluster: cluster_name }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :sync, params: { cluster: cluster_name }
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should upload tokens to selected cluster' do
          expect(Kubernetes::TokenSyncService).to receive(:sync_tokens).with(cluster_name)
          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'sync_kubernetes_tokens',
            data: { cluster: cluster_name },
            comment: "Kubernetes tokens synced to `#{cluster_name}` cluster."
          )

          post :sync, params: { cluster: cluster_name }

          expect(response).to have_http_status(:no_content)
        end

        context 'when upload service throws an exception' do
          before do
            allow(Kubernetes::TokenSyncService).to receive(:sync_tokens).with(cluster_name).and_raise("some error message")
          end

          it 'renders error to the client' do
            expect(AuditService).to receive(:log).never

            post :sync, params: { cluster: cluster_name }

            expect(response).to have_http_status(:unprocessable_entity)
            expect(json_response['error']['message']).to eq "Kubernetes tokens sync to `#{cluster_name}` cluster failed - some error message"
          end
        end

      end
    end
  end
end
