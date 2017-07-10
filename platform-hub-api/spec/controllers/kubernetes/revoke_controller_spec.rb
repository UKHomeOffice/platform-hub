require 'rails_helper'

RSpec.describe Kubernetes::RevokeController, type: :controller do

  let(:token) { 'some-token' }

  describe 'POST #revoke' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post :revoke, params: { token: token }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :revoke, params: { token: token }
        end
      end

      it_behaves_like 'an admin' do
        let(:cluster) { 'development' }
        let(:msg) { 'message from service' }
        let(:summary) { [ [cluster, msg] ] }

        it 'should remove token' do
          expect(Kubernetes::TokenRevokeService).to receive(:remove).with(token) { summary }
          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'revoke_kubernetes_token',
            data: { cluster: cluster, token: token },
            comment: msg
          )

          post :revoke, params: { token: token }

          expect(response).to have_http_status(:no_content)
        end

        context 'when token revoke service throws an exception' do

          context 'with TokenNotFound' do
            before do
              allow(Kubernetes::TokenRevokeService).to receive(:remove).with(token)
                .and_raise(Kubernetes::TokenRevokeService::Errors::TokenNotFound)
            end

            it 'renders error to the client' do
              expect(AuditService).to receive(:log).never

              post :revoke, params: { token: token }

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response['error']['message']).to eq 'Kubernetes token not found.'
            end
          end

          context 'with any other exception' do
            before do
              allow(Kubernetes::TokenRevokeService).to receive(:remove).with(token)
                .and_raise("any-other-error")
            end

            it 'renders error to the client' do
              expect(AuditService).to receive(:log).never

              post :revoke, params: { token: token }

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response['error']['message']).to eq "Kubernetes token revoke failed - any-other-error"
            end
          end

        end
      end
    end
  end
end
