require 'rails_helper'

RSpec.describe Kubernetes::RobotTokensController, type: :controller do

  let(:cluster) { 'foo' }

  let :token1 do
    {
      'token' => ENCRYPTOR.encrypt('token1'),
      'user' => 'user1',
      'uid' => 'uid1',
      'description' => 'desc1'
    }
  end

  let :token2 do
    {
      'token' => ENCRYPTOR.encrypt('token2'),
      'user' => 'user2',
      'uid' => 'uid2',
      'description' => 'desc2'
    }
  end

  def create_hash_record
    create :kubernetes_robot_tokens_hash_record,
      cluster: cluster,
      data: [
        token1,
        token2
      ]
  end

  describe 'GET #index' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index, params: { cluster: cluster }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :index, params: { cluster: cluster }
        end
      end

      it_behaves_like 'an admin' do

        context 'no tokens yet' do
          it 'should return an empty response' do
            get :index,  params: { cluster: cluster }
            expect(response).to be_success
            expect(json_response).to eq []
          end
        end

        context 'with some tokens in a particular cluster' do
          before do
            create_hash_record
          end

          it 'should return the expected tokens' do
            get :index, params: { cluster: cluster }
            expect(response).to be_success
            expect(json_response).to eq [
              {
                'cluster' => cluster,
                'token' => 'token1',
                'uid' => 'uid1',
                'groups' => nil,
                'name' => 'user1',
                'description' => 'desc1'
              },
              {
                'cluster' => cluster,
                'token' => 'token2',
                'uid' => 'uid2',
                'groups' => nil,
                'name' => 'user2',
                'description' => 'desc2'
              }
            ]
          end

          it 'should not return any tokens for a different cluster' do
            get :index, params: { cluster: cluster + '_other' }
            expect(response).to be_success
            expect(json_response).to eq []
          end
        end

      end

    end

  end

  describe 'PUT/PATCH #create_or_update' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        put :create_or_update, params: { cluster: cluster, name: 'foo' }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden' do
        before do
          put :create_or_update, params: { cluster: cluster, name: 'foo' }
        end
      end

      it_behaves_like 'an admin' do
        context 'for a new token name' do
          let(:name) { token1['user'] }

          it 'should create a new token' do
            expect(AuditService).to receive(:log)
              .with(
                context: anything,
                action: 'update_kubernetes_robot_token',
                data: { cluster: cluster, name: name, user_id: nil  },
                comment: "Kubernetes `#{cluster}` robot token '#{name}' created or updated"
              )

            expect(Kubernetes::RobotTokenService.get_by_cluster(cluster).length).to eq 0
            put :create_or_update, params: { cluster: cluster, name: name }
            expect(response).to be_success
            expect(response).to have_http_status 204
            expect(Kubernetes::RobotTokenService.get_by_cluster(cluster).length).to eq 1
          end
        end

        context 'for an existing token name' do
          let(:name) { token1['user'] }

          before do
            create_hash_record
          end

          it 'should update the existing one in place' do
            expect(AuditService).to receive(:log)
              .with(
                context: anything,
                action: 'update_kubernetes_robot_token',
                data: { cluster: cluster, name: name, user_id: 'user_id'  },
                comment: "Kubernetes `#{cluster}` robot token '#{name}' created or updated"
              )

            expect(Kubernetes::RobotTokenService.get_by_cluster(cluster).length).to eq 2
            put :create_or_update, params: { cluster: cluster, name: name, groups: ['foo'], description: 'desc', user_id: 'user_id' }
            expect(response).to be_success
            expect(response).to have_http_status 204
            tokens = Kubernetes::RobotTokenService.get_by_cluster(cluster)
            expect(tokens.length).to eq 2
            token = tokens.find { |t| t.name == name }
            expect(token).not_to be nil
            expect(token.groups).to eq ['foo']
            expect(token.description).to eq 'desc'
            expect(token.user_id).to eq 'user_id'
          end
        end
      end

    end

  end

  describe 'DELETE #destroy' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        delete :destroy, params: { cluster: cluster, name: 'foo' }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { cluster: cluster, name: 'foo' }
        end
      end

      it_behaves_like 'an admin' do

        before do
          create_hash_record
        end

        context 'for a token that does not exist' do
          let(:name) { "#{token1['user']}_other" }

          it 'should handle the deletion gracefully and without complaining' do
            expect(AuditService).to receive(:log)
              .with(
                context: anything,
                action: 'destroy_kubernetes_robot_token',
                data: { cluster: cluster, name: name },
                comment: "Kubernetes `#{cluster}` robot token '#{name}' removed"
              )

            delete :destroy, params: { cluster: cluster, name: name }

            expect(response).to be_success
            expect(response).to have_http_status 204
            expect(Kubernetes::RobotTokenService.get_by_cluster(cluster).length).to eq 2
          end
        end

        context 'for a token that does exist' do
          let(:name) { token1['user'] }

          it 'should delete the token specified' do
            expect(AuditService).to receive(:log)
              .with(
                context: anything,
                action: 'destroy_kubernetes_robot_token',
                data: { cluster: cluster, name: name  },
                comment: "Kubernetes `#{cluster}` robot token '#{name}' removed"
              )

            delete :destroy, params: { cluster: cluster, name: name }

            expect(response).to be_success
            expect(response).to have_http_status 204
            expect(Kubernetes::RobotTokenService.get_by_cluster(cluster).length).to eq 1
          end
        end

        context 'for a token with the same name but in a different cluster' do
          let(:name) { token1['user'] }
          let(:other_cluster) { "#{cluster}_other" }

          it 'should handle the deletion gracefully and without complaining' do
            expect(AuditService).to receive(:log)
              .with(
                context: anything,
                action: 'destroy_kubernetes_robot_token',
                data: { cluster: other_cluster, name: name  },
                comment: "Kubernetes `#{other_cluster}` robot token '#{name}' removed"
              )

            delete :destroy, params: { cluster: other_cluster, name: name }

            expect(response).to be_success
            expect(response).to have_http_status 204
            expect(Kubernetes::RobotTokenService.get_by_cluster(cluster).length).to eq 2
          end
        end

      end

    end

  end

end
