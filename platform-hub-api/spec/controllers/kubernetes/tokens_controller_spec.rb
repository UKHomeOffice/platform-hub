require 'rails_helper'

RSpec.describe Kubernetes::TokensController, type: :controller do
  include_context 'time helpers'

  let(:cluster_name) { 'development' }
  let(:groups) { ['group1', 'group2'] }
  let(:token) { 'some-token' }
  let(:uid) { 'some-uid' }

  before do
    create(:kubernetes_cluster, name: cluster_name)

    @user = create(:user)

    @kubernetes_identity = create(:kubernetes_identity, user: @user, data: { tokens: [] })
    user_kube_token = {
      identity_id: @kubernetes_identity.id,
      cluster: cluster_name,
      token: ENCRYPTOR.encrypt(token),
      uid: uid,
      groups: groups
    }
    @kubernetes_identity.data["tokens"] << user_kube_token
    @kubernetes_identity.save!
  end

  describe 'GET #index' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index, params: { user_id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :index, params: { user_id: @user.id }
        end
      end

      it_behaves_like 'an admin' do
        it 'should return a list of all user tokens' do
          get :index, params: { user_id: @user.id }
          expect(response).to be_success
          expect(json_response.length).to eq 1
          expect(json_response.first['cluster']).to eq cluster_name
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
        put :create_or_update, params: { user_id: @user.id, cluster: cluster_name }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          put :create_or_update, params: { user_id: @user.id, cluster: cluster_name }
        end
      end

      it_behaves_like 'an admin' do
        let(:new_groups) { ['new-group'] }

        it 'should create or update token and return it' do
          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'update_kubernetes_identity',
            auditable: @kubernetes_identity,
            data: { cluster: cluster_name },
            comment: "Kubernetes `#{cluster_name}` token created or updated for user '#{@kubernetes_identity.user.email}' - Assigned groups: #{new_groups}"
          )

          put :create_or_update, params: {
            user_id: @user.id,
            cluster: cluster_name,
            token: { groups: new_groups }
          }

          expect(response).to be_success
          expect(json_response['cluster']).to eq cluster_name
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
        delete :destroy, params: { user_id: @user.id, cluster: cluster_name }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { user_id: @user.id, cluster: cluster_name }
        end
      end

      it_behaves_like 'an admin' do
        it 'should delete token' do
          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'update_kubernetes_identity',
            auditable: @kubernetes_identity,
            data: { cluster: cluster_name },
            comment: "Kubernetes `#{cluster_name}` token removed for user '#{@kubernetes_identity.user.email}'"
          )

          delete :destroy, params: { user_id: @user.id, cluster: cluster_name }

          expect(response).to have_http_status(:no_content)
        end
      end

    end

  end

  describe 'POST #escalate' do
    let(:privileged_group) { 'privileged-group' }
    let(:expires_in_secs) { 180 }

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post :escalate, params: { 
          user_id: @user.id, 
          cluster: cluster_name, 
          privileged_group: privileged_group, 
          expires_in_secs: expires_in_secs 
        }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :escalate, params: { 
            user_id: @user.id, 
            cluster: cluster_name, 
            privileged_group: privileged_group, 
            expires_in_secs: expires_in_secs 
          }
        end
      end

      it_behaves_like 'an admin' do
        it 'should escalate token and return it' do
          move_time_to now

          expected_groups = groups << privileged_group

          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'escalate_kubernetes_token',
            auditable: @kubernetes_identity,
            data: { 
              cluster: cluster_name,
              privileged_group: privileged_group, 
              expire_privileged_at: expires_in_secs.seconds.from_now
            },
            comment: "Kubernetes `#{cluster_name}` token escalated for user '#{@kubernetes_identity.user.email}' - Assigned groups: #{expected_groups}"
          )

          post :escalate, params: { 
            user_id: @user.id, 
            cluster: cluster_name, 
            privileged_group: privileged_group, 
            expires_in_secs: expires_in_secs 
          }

          expect(response).to be_success
          expect(json_response['cluster']).to eq cluster_name
          expect(json_response['token']).to eq token
          expect(json_response['uid']).to eq uid
          expect(json_response['groups']).to match_array expected_groups
          expect(Time.parse(json_response['expire_privileged_at']).to_s(:db)).to eq expires_in_secs.seconds.from_now.to_s(:db)
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
              expect(@user.identities).to receive(:create!).never

              get :index, params: { user_id: @user.id }
            end
          end

          context 'when kubernetes identity does not exist yet' do
            before do
              @user.identities = []
            end

            it 'creates a new one and returns it' do
              get :index, params: { user_id: @user.id }

              expect(@user.identities.count).to eq 1
              kube_identity = @user.identity(:kubernetes)
              expect(kube_identity.provider).to eq "kubernetes"
              expect(kube_identity.external_id).to eq @user.email
            end
          end
        end
      end

    end

  end

end
