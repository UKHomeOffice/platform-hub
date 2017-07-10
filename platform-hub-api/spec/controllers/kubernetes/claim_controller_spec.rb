require 'rails_helper'

RSpec.describe Kubernetes::ClaimController, type: :controller do

  let(:token) { 'some-token' }

  describe 'POST #claim' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post :claim, params: { token: token }
      end
    end

    it_behaves_like 'authenticated' do
      let(:cluster) { 'development' }
      let(:msg) { 'message from service' }
      let(:summary) { [ [cluster, msg] ] }

      it 'should claim token' do
        expect(Kubernetes::TokenClaimService).to receive(:claim_token).with(current_user, token) { summary }
        expect(AuditService).to receive(:log).with(
          context: anything,
          action: 'claim_kubernetes_token',
          data: { cluster: cluster, user_id: current_user.id, token: anything },
          comment: msg
        )

        post :claim, params: { token: token }

        expect(response).to have_http_status(:no_content)
      end

      context 'when token claim service throws an exception' do

        context 'with TokenNotFound' do
          before do
            allow(Kubernetes::TokenClaimService).to receive(:claim_token).with(current_user, token)
              .and_raise(Kubernetes::TokenClaimService::Errors::TokenNotFound)
          end

          it 'renders error to the client' do
            expect(AuditService).to receive(:log).never

            post :claim, params: { token: token }

            expect(response).to have_http_status(:unprocessable_entity)
            expect(json_response['error']['message']).to eq 'Kubernetes token not found.'
          end
        end

        context 'with TokenAlreadyClaimed' do
          before do
            allow(Kubernetes::TokenClaimService).to receive(:claim_token).with(current_user, token)
              .and_raise(Kubernetes::TokenClaimService::Errors::TokenAlreadyClaimed)
          end

          it 'renders error to the client' do
            expect(AuditService).to receive(:log).never

            post :claim, params: { token: token }

            expect(response).to have_http_status(:unprocessable_entity)
            expect(json_response['error']['message']).to eq 'Kubernetes token already claimed.'
          end
        end

        context 'with any other exception' do
          before do
            allow(Kubernetes::TokenClaimService).to receive(:claim_token).with(current_user, token)
              .and_raise("any-other-error")
          end

          it 'renders error to the client' do
            expect(AuditService).to receive(:log).never

            post :claim, params: { token: token }

            expect(response).to have_http_status(:unprocessable_entity)
            expect(json_response['error']['message']).to eq 'Kubernetes token claim failed. Try again later.'
          end
        end

      end
    end
  end
end
