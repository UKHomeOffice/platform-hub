require 'rails_helper'

RSpec.describe Kubernetes::RevokeController, type: :controller do

  before do
    @token = create :user_kubernetes_token
  end

  describe 'POST #revoke' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post :revoke, params: { token: @token.decrypted_token }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :revoke, params: { token: @token.decrypted_token }
        end
      end

      it_behaves_like 'an admin' do

        context 'for existing token' do
          it 'should remove token' do
            expect(AuditService).to receive(:log).with(
              context: anything,
              action: 'destroy',
              auditable: @token,
              data: {
                cluster: @token.cluster.name
              },
              comment: "User '#{current_user.email}' revoked `#{@token.cluster.name}` token (name: '#{@token.name}')"
            )

            post :revoke, params: { token: @token.decrypted_token }
            expect(response).to have_http_status(:no_content)
          end
        end

        context 'when token does not exist' do
          it 'is a noop' do
            expect(AuditService).to receive(:log).never

            post :revoke, params: { token: 'unknown-token' }
            expect(response).to have_http_status(:not_found)
          end
        end

      end
    end
  end
end
