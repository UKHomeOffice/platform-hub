require 'rails_helper'

RSpec.describe Kubernetes::TokensController, type: :controller do

  let(:user) { build(:user) }
  let(:user_identities) { double }
  let(:cluster) { 'development' }
  let(:groups) { ['group1', 'group2'] }
  let(:token) { 'some-token' }
  let(:uid) { 'some-uid' }

  let(:kubernetes_identity) { instance_double('Identity', provider: :kubernetes) }

  let(:kube_token) do
    {
      identity_id: kubernetes_identity.id,
      cluster: cluster,
      token: ENCRYPTOR.encrypt(token),
      uid: uid,
      groups: groups
    }
  end

  before do
    allow(kubernetes_identity).to receive(:data) { { tokens: [kube_token] } }
    allow(kubernetes_identity).to receive(:id) { 'some-kube-identity-id' }
    allow(kubernetes_identity).to receive(:user) { user }
    allow(User).to receive(:find).with(user.id) { user }
    allow(user).to receive(:identity).with(:kubernetes) { kubernetes_identity }
    allow(user).to receive(:identities) { user_identities }
  end

  describe 'GET #index' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index, params: { user_id: user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :index, params: { user_id: user.id }
        end
      end

      it_behaves_like 'an admin' do
        it 'should return a list of all user tokens' do
         get :index, params: { user_id: user.id }
         expect(response).to be_success
         expect(json_response.length).to eq 1
         expect(json_response.first['cluster']).to eq cluster
         expect(json_response.first['token']).to eq token
         expect(json_response.first['uid']).to eq uid
         expect(json_response.first['groups']).to match_array groups
        end 
      end

    end

  end

  describe 'PATCH/PUT #create_or_update' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :create_or_update, params: { user_id: user.id, cluster: cluster }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :create_or_update, params: { user_id: user.id, cluster: cluster }
        end
      end

      it_behaves_like 'an admin' do
        let(:new_groups) { ['new-group'] }
        let(:tokens) { double(:tokens) }
        let(:created_or_updated_token) do 
          build(:kubernetes_token, 
            identity_id: kubernetes_identity.id,
            cluster: cluster,
            token: token,
            uid: uid,
            groups: new_groups
          )
        end

        it 'should create or update token and return it' do
          expect(Kubernetes::TokenService).to receive(:create_or_update_token).with(
            kubernetes_identity.data,
            kubernetes_identity.id,
            cluster,
            new_groups
          ) { [ tokens, created_or_updated_token ] }

          allow(created_or_updated_token).to receive(:valid?) { true }
          allow(kubernetes_identity).to receive(:with_lock).and_yield
          allow(kubernetes_identity).to receive(:save!) { true }

          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'update_kubernetes_identity',
            auditable: kubernetes_identity,
            data: { cluster: cluster },
            comment: "Kubernetes `#{cluster}` token created or updated for user '#{kubernetes_identity.user.email}' - Assigned groups: #{created_or_updated_token.groups}"
          )

          get :create_or_update, params: { 
            user_id: user.id, 
            cluster: cluster, 
            token: { groups: new_groups } 
          }

          expect(response).to be_success
          expect(json_response['cluster']).to eq cluster
          expect(json_response['token']).to eq token
          expect(json_response['uid']).to eq uid
          expect(json_response['groups']).to match_array new_groups
        end 
      end

    end

  end

  describe 'DELETE #destroy' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :destroy, params: { user_id: user.id, cluster: cluster }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :destroy, params: { user_id: user.id, cluster: cluster }
        end
      end

      it_behaves_like 'an admin' do
        it 'should delete token' do
          expect(Kubernetes::TokenService).to receive(:delete_token).with(
            kubernetes_identity.data,
            cluster
          )

          allow(kubernetes_identity).to receive(:with_lock).and_yield
          allow(kubernetes_identity).to receive(:save!) { true }

          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'update_kubernetes_identity',
            auditable: kubernetes_identity,
            data: { cluster: cluster },
            comment: "Kubernetes `#{cluster}` token removed for user '#{kubernetes_identity.user.email}'"
          )

          post :destroy, params: { user_id: user.id, cluster: cluster }

          expect(response).to have_http_status(:no_content)
        end
      end

    end

  end

  describe 'before actions' do

    describe '#find_identity' do

      it_behaves_like 'authenticated' do
        it_behaves_like 'an admin' do
          before do
            expect(controller).to receive(:find_identity).and_call_original
          end

          context 'when kubernetes identity exists' do
            it 'returns it' do
              expect(user_identities).to receive(:create!).never

              get :index, params: { user_id: user.id }
            end
          end

          context 'when kubernetes identity does not exist yet' do
            before do
              expect(user).to receive(:identity).with(:kubernetes) { nil }
            end

            it 'creates a new one and returns it' do
              expect(user_identities).to receive(:create!).with(
                provider: :kubernetes,
                external_id: user.email,
                data: {tokens: []}
              ) { build(:kubernetes_identity, data: {tokens: []}) }

              get :index, params: { user_id: user.id }
            end
          end
        end
      end

    end

  end

end
