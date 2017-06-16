require 'rails_helper'

RSpec.describe Kubernetes::SyncController, type: :controller do

  let(:cluster) { 'development' }

  describe 'POST #sync' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post :sync, params: { cluster: cluster }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :sync, params: { cluster: cluster }
        end
      end

      it_behaves_like 'an admin' do

        it 'should upload tokens to selected cluster' do
          expect(Kubernetes::TokenSyncService).to receive(:sync_tokens).with(cluster: cluster)
          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'sync_kubernetes_tokens',
            data: { cluster: cluster },
            comment: "Kubernetes tokens synced to `#{cluster}` cluster."
          )

          post :sync, params: { cluster: cluster }

          expect(response).to have_http_status(:no_content)
        end

        context 'when upload service throws an exception' do
          before do
            allow(Kubernetes::TokenSyncService).to receive(:sync_tokens).with(cluster: cluster).and_raise("some error message")
          end

          it 'renders error to the client' do
            expect(AuditService).to receive(:log).never

            post :sync, params: { cluster: cluster }

            expect(response).to have_http_status(:unprocessable_entity)
            expect(json_response['error']['message']).to eq "Kubernetes tokens sync to `#{cluster}` cluster failed - some error message"
          end
        end

      end
    end
  end
end
