require 'rails_helper'

RSpec.describe Kubernetes::TokensController, type: :controller do
  include_context 'time helpers'

  let(:cluster_name) { 'development' }

  before do
    @user = create(:user)
    @kube_identity = create(:kubernetes_identity, user: @user)
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

        context 'for user tokens' do

          context 'when tokens belong to current user' do
            before do
              @token = create :user_kubernetes_token, tokenable: create(:kubernetes_identity, user: current_user)
            end

            it 'returns list of tokens with token value revealed' do
              get :index, params: { kind: 'user', user_id: current_user.id }
              expect(response).to be_success
              expect(json_response.length).to eq 1
              expect(json_response.first['cluster']['name']).to eq @token.cluster.name
              expect(json_response.first['token']).to eq @token.decrypted_token
              expect(json_response.first['obfuscated_token']).to eq @token.obfuscated_token
              expect(json_response.first['uid']).to eq @token.uid
              expect(json_response.first['name']).to eq @token.name
              expect(json_response.first['groups']).to match_array @token.groups
              expect(json_response.first['description']).to eq nil
              expect(json_response.first['kind']).to eq 'user'
            end
          end

          context 'when tokens do not belong to current user' do
            before do
              @token = create :user_kubernetes_token, tokenable: @kube_identity
            end

            it 'should return a list of all user tokens with obfuscated token only' do
              get :index, params: { kind: 'user', user_id: @user.id }
              expect(response).to be_success
              expect(json_response.length).to eq 1
              expect(json_response.first['cluster']['name']).to eq @token.cluster.name
              expect(json_response.first['obfuscated_token']).to eq @token.obfuscated_token
              expect(json_response.first['token']).to be_nil
              expect(json_response.first['uid']).to eq @token.uid
              expect(json_response.first['name']).to eq @token.name
              expect(json_response.first['groups']).to match_array @token.groups
              expect(json_response.first['description']).to eq nil
              expect(json_response.first['kind']).to eq 'user'
            end
          end
        end

        context 'for robot tokens' do
          before do
            @token = create :robot_kubernetes_token
          end

          it 'should return a list of all robot tokens' do
            get :index, params: { kind: 'robot', cluster_name: @token.cluster.name }
            expect(response).to be_success
            expect(json_response.length).to eq 1
            expect(json_response.first['cluster']['name']).to eq @token.cluster.name
            expect(json_response.first['token']).to eq @token.decrypted_token
            expect(json_response.first['uid']).to eq @token.uid
            expect(json_response.first['name']).to eq @token.name
            expect(json_response.first['groups']).to match_array @token.groups
            expect(json_response.first['description']).to eq @token.description
            expect(json_response.first['kind']).to eq 'robot'
          end
        end

        context 'when user does not yet have a kubernetes identity' do
          before do
            @user = create :user
          end

          it 'should still return no tokens' do
            expect(@user.kubernetes_identity).to eq nil
            get :index, params: { kind: 'user', user_id: @user.id }
            expect(response).to be_success
            expect(json_response).to eq []
          end
        end

      end
    end
  end

  describe 'GET #show' do
    before do
      @user = create :user
      @identity = create :identity, user: @user
      @token = create :user_kubernetes_token, tokenable: @identity
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @token.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :show, params: { id: @token.id }
        end
      end

      it_behaves_like 'an admin' do

        context 'for a non-existent token' do
          it 'should return a 404' do
            get :show, params: { id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a user token that exists and belongs to current user' do
          before do
            @token = create :user_kubernetes_token, tokenable: create(:kubernetes_identity, user: current_user)
          end

          it 'should return the specified token resource with token revealed' do
            get :show, params: { id: @token.id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @token.id,
              'kind' => 'user',
              'obfuscated_token' => @token.obfuscated_token,
              'token' => @token.decrypted_token,
              'name' => @token.name,
              'uid' => @token.uid,
              'groups' => @token.groups,
              'cluster' => {
                'id' => @token.cluster.friendly_id,
                'name' => @token.cluster.name,
                'description' => @token.cluster.description
              },
              'user' => {
                'id' => current_user.id,
                'name' => current_user.name,
                'email' => current_user.email,
                'is_active' => current_user.is_active,
                'is_managerial' => current_user.is_managerial,
                'is_technical' => current_user.is_technical
              },
              'project'=> {
                'id' => @token.project.friendly_id,
                'shortname' => @token.project.shortname,
                'name' => @token.project.name
              }
            })
          end
        end

        context 'for a user token that exists but does not belong to current user' do
          it 'should return the specified token resource but never expose token value' do
            get :show, params: { id: @token.id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @token.id,
              'kind' => 'user',
              'obfuscated_token' => @token.obfuscated_token,
              'name' => @token.name,
              'uid' => @token.uid,
              'groups' => @token.groups,
              'cluster' => {
                'id' => @token.cluster.friendly_id,
                'name' => @token.cluster.name,
                'description' => @token.cluster.description
              },
              'user' => {
                'id' => @user.id,
                'name' => @user.name,
                'email' => @user.email,
                'is_active' => @user.is_active,
                'is_managerial' => @user.is_managerial,
                'is_technical' => @user.is_technical
              },
              'project'=> {
                'id' => @token.project.friendly_id,
                'shortname' => @token.project.shortname,
                'name' => @token.project.name
              }
            })
            expect(json_response['token']).to be_nil
          end
        end

        context 'for a robot token that exists' do
          before do
            @token = create :robot_kubernetes_token
          end

          it 'should return the specified token resource' do
            get :show, params: { id: @token.id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @token.id,
              'kind' => 'robot',
              'obfuscated_token' => @token.obfuscated_token,
              'token' => @token.decrypted_token,
              'name' => @token.name,
              'uid' => @token.uid,
              'groups' => @token.groups,
              'cluster' => {
                'id' => @token.cluster.friendly_id,
                'name' => @token.cluster.name,
                'description' => @token.cluster.description
              },
              'description' => @token.description,
              'service' => {
                'id' => @token.tokenable.id,
                'name' => @token.tokenable.name,
                'description' => @token.tokenable.description,
                'project'=> {
                  'id' => @token.tokenable.project.friendly_id,
                  'shortname' => @token.tokenable.project.shortname,
                  'name' => @token.tokenable.project.name
                }
              },
              'project'=> {
                'id' => @token.project.friendly_id,
                'shortname' => @token.project.shortname,
                'name' => @token.project.name
              }
            })
          end
        end

        context 'for escalated token with expiration date set' do
          let!(:project) { create :project }
          let!(:privileged_group) { create :kubernetes_group, :privileged, :for_user, allocate_to: project }
          let(:escalation_time_in_secs) { 60 }

          before do
            @token = create :user_kubernetes_token, project: project
            @token.escalate(privileged_group.name, escalation_time_in_secs)
          end

          it 'should present expire_privileged_at' do
            get :show, params: { id: @token.id }
            expect(response).to be_success
            expect(
              DateTime.parse(json_response['expire_privileged_at']).to_s(:db)
            ).to eq @token.expire_privileged_at.to_s(:db)
          end
        end

      end
    end
  end

  describe 'POST #create' do
    let(:project) { create :project }
    let(:cluster) { create(:kubernetes_cluster, allocate_to: project) }
    let(:user_group_1) { create :kubernetes_group, :not_privileged, :for_user, allocate_to: project }
    let(:user_group_2) { create :kubernetes_group, :not_privileged, :for_user, allocate_to: project }

    before do
      @user = create(:user)
      create :project_membership, project: project, user: @user
    end

    let(:kind) { 'user' }
    let(:name) { nil }
    let(:description) { nil }

    let :token_data do
      {
        kind: kind,
        project_id: project.friendly_id,
        cluster_name: cluster.name,
        groups: [ user_group_1.name, user_group_2.name ],
        name: name,
        description: description
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :create, params: { token: token_data }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :create, params: { token: token_data }
        end
      end

      it_behaves_like 'an admin' do

        context 'for user' do

          it 'creates a new kubernetes token as expected' do
            expect(KubernetesToken.count).to eq 0
            expect(Audit.count).to eq 0
            post :create, params: { token: token_data.merge(user_id: @user.id) }
            expect(response).to be_success
            expect(KubernetesToken.count).to eq 1
            token = KubernetesToken.first
            expect(token.tokenable).to eq @user.kubernetes_identity
            new_token_internal_id = token.id
            expect(json_response['kind']).to eq 'user'
            expect(json_response['obfuscated_token'].length).to eq 36
            expect(json_response['token']).to be_nil
            expect(json_response['uid'].length).to eq 36
            expect(json_response['name']).to eq @user.email
            expect(json_response['groups']).to match_array [ user_group_1.name, user_group_2.name ]
            expect(json_response['cluster']['name']).to eq cluster.name
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'create'
            expect(audit.auditable.id).to eq new_token_internal_id
            expect(audit.user.id).to eq current_user_id
            expect(audit.data['cluster']).to eq cluster.name
          end

        end

        context 'for robot' do
          let(:kind) { 'robot' }
          let(:name) { 'some_robot_name' }
          let(:description) { 'Robot to do things' }
          let!(:service) { create :service }
          let!(:cluster) { create :kubernetes_cluster, allocate_to: service.project }
          let!(:robot_group_1) { create :kubernetes_group, :not_privileged, :for_robot, allocate_to: service }
          let!(:robot_group_2) { create :kubernetes_group, :not_privileged, :for_robot, allocate_to: service }

          it 'creates a new kubernetes token as expected' do
            expect(KubernetesToken.count).to eq 0
            expect(Audit.count).to eq 0
            post :create, params: { token: token_data.merge(cluster_name: cluster.name, service_id: service.id, groups: [ robot_group_1.name, robot_group_2.name ]) }
            expect(response).to be_success
            expect(KubernetesToken.count).to eq 1
            token = KubernetesToken.first
            expect(token.tokenable).to eq service
            new_token_internal_id = token.id
            expect(json_response['kind']).to eq 'robot'
            expect(json_response['token'].length).to eq 36
            expect(json_response['uid'].length).to eq 36
            expect(json_response['name']).to eq name
            expect(json_response['groups']).to match_array [ robot_group_1.name, robot_group_2.name ]
            expect(json_response['cluster']['name']).to eq cluster.name
            expect(json_response['description']).to eq description
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'create'
            expect(audit.auditable.id).to eq new_token_internal_id
            expect(audit.user.id).to eq current_user_id
            expect(audit.data['cluster']).to eq cluster.name
          end

        end
      end
    end
  end

  describe 'PUT #update' do
    let(:project) { create :project }
    let(:user_group_1) { create :kubernetes_group, :not_privileged, :for_user, allocate_to: project }
    let(:user_group_2) { create :kubernetes_group, :not_privileged, :for_user, allocate_to: project }

    before do
      @token = create :user_kubernetes_token, project: project
    end

    let(:kind) { 'user' }
    let(:name) { nil }
    let(:description) { nil }

    let :put_data do
      {
        id: @token.id,
        token: {
          kind: kind,
          cluster_name: @token.cluster.name,
          groups: "#{user_group_1.name},#{user_group_2.name}",
          name: name,
          description: description
        }
      }
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

        context 'for user token' do

          it 'updates the specified token groups only' do
            expect(KubernetesToken.user.count).to eq 1
            old = KubernetesToken.user.first
            expect(old.groups).to eq @token.groups
            expect(Audit.count).to eq 0

            expect(AuditService).to receive(:log).with(
              context: anything,
              action: 'update',
              auditable: @token,
              data: {
                cluster: @token.cluster.name
              }
            ).and_call_original

            put :update, params: put_data
            expect(response).to be_success
            expect(KubernetesToken.user.count).to eq 1
            updated = KubernetesToken.user.first
            expect(updated.kind).to eq 'user'
            expect(updated.name).to eq @token.name
            expect(updated.cluster).to eq @token.cluster
            expect(updated.groups).to match_array put_data[:token][:groups].split(",")
            expect(Audit.count).to eq 1
          end

        end

        context 'for robot token' do
          before do
            @token = create :robot_kubernetes_token
          end

          let(:kind) { 'robot' }
          let(:description) { 'old_description' }
          let!(:robot_group_1) { create :kubernetes_group, :not_privileged, :for_robot, allocate_to: @token.tokenable }
          let!(:robot_group_2) { create :kubernetes_group, :not_privileged, :for_robot, allocate_to: @token.tokenable }

          it 'updates the specified token description, groups and associated user only' do
            expect(KubernetesToken.robot.count).to eq 1
            old = KubernetesToken.robot.first
            expect(old.description).to eq @token.description
            expect(old.groups).to eq @token.groups
            expect(Audit.count).to eq 0

            expect(AuditService).to receive(:log).with(
              context: anything,
              action: 'update',
              auditable: @token,
              data: {
                cluster: @token.cluster.name
              }
            ).and_call_original

            put :update, params: { id: @token.id, token: put_data[:token].merge({ groups: [ robot_group_1.name, robot_group_2.name ] }) }
            expect(response).to be_success
            expect(KubernetesToken.robot.count).to eq 1
            updated = KubernetesToken.robot.first
            expect(updated.kind).to eq 'robot'
            expect(updated.cluster).to eq @token.cluster
            expect(updated.name).to eq @token.name
            expect(updated.description).to eq put_data[:token][:description]
            expect(updated.groups).to match_array [ robot_group_1.name, robot_group_2.name ]
            expect(Audit.count).to eq 1
          end

        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @token = create :user_kubernetes_token
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @token.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { id: @token.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should delete the specified token' do
          expect(KubernetesToken.exists?(@token.id)).to be true
          expect(Audit.count).to eq 0

          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'destroy',
            auditable: @token,
            data: {
              cluster: @token.cluster.name
            },
            comment: "User '#{current_user.email}' deleted #{@token.kind} token (cluster: #{@token.cluster.name}, name: #{@token.name})"
          ).and_call_original

          delete :destroy, params: { id: @token.id }
          expect(response).to be_success
          expect(KubernetesToken.exists?(@token.id)).to be false
          expect(Audit.count).to eq 1
        end

      end

    end
  end

  describe 'PATCH #escalate' do
    let(:project) { create :project }
    let(:privileged_group) { create :kubernetes_group, :privileged, :for_user, allocate_to: project }
    let(:expires_in_secs) { 180 }

    before do
      @token = create :user_kubernetes_token, project: project
    end

    let(:escalate_params) do
      {
        id: @token.id,
        privileged_group: privileged_group.name,
        expires_in_secs: expires_in_secs
      }
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        patch :escalate, params: escalate_params
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          patch :escalate, params: escalate_params
        end
      end

      it_behaves_like 'an admin' do
        it 'should escalate token and return it' do
          move_time_to now

          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'escalate',
            auditable: @token,
            data: {
              cluster: @token.cluster.name,
              privileged_group: privileged_group.name
            }
          ).and_call_original

          patch :escalate, params: escalate_params

          expect(response).to be_success
          expect(json_response['cluster']['name']).to eq @token.cluster.name
          expect(json_response['obfuscated_token']).to eq @token.obfuscated_token
          expect(json_response['uid']).to eq @token.uid
          expect(json_response['groups']).to match_array @token.groups << privileged_group.name
          expect(DateTime.parse(json_response['expire_privileged_at']).to_s(:db)).to eq expires_in_secs.seconds.from_now.to_s(:db)
          expect(Audit.count).to eq 1
        end

        context 'with privileged expiration greater than 6h' do
          let(:expires_in_secs) { 7 * 3600 } #7h

          it 'limits expiration time to maximum 6h from now' do
            move_time_to now

            patch :escalate, params: escalate_params

            expect(response).to be_success
            expect(
              DateTime.parse(json_response['expire_privileged_at']).to_s(:db)
            ).to eq KubernetesToken::PRIVILEGED_GROUP_MAX_EXPIRATION_SECONDS.seconds.from_now.to_s(:db)
          end
        end
      end

    end

  end

  describe 'PATCH #deescalate' do
    let(:project) { create :project }
    let(:privileged_group) { create :kubernetes_group, :privileged, :for_user, allocate_to: project }
    let(:escalation_time_in_secs) { 60 }

    before do
      @token = create :user_kubernetes_token, project: project
      @token.escalate(privileged_group.name, escalation_time_in_secs)
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        patch :deescalate, params: { id: @token.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          patch :deescalate, params: { id: @token.id }
        end
      end

      it_behaves_like 'an admin' do
        before do
          move_time_to (escalation_time_in_secs + 1).seconds.from_now
        end

        it 'should deescalate token and return it' do
          expect(AuditService).to receive(:log).with(
            context: anything,
            action: 'deescalate',
            auditable: @token,
            data: {
              cluster: @token.cluster.name
            }
          ).and_call_original

          patch :deescalate, params: { id: @token.id }

          expect(response).to be_success
          expect(json_response['cluster']['name']).to eq @token.cluster.name
          expect(json_response['obfuscated_token']).to eq @token.obfuscated_token
          expect(json_response['uid']).to eq @token.uid
          expect(json_response['groups']).to be_blank
          expect(json_response['expire_privileged_at']).to eq nil
          expect(Audit.count).to eq 1
        end
      end

    end

  end

end
