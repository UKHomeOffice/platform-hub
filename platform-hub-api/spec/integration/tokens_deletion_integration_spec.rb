require 'rails_helper'

RSpec.describe 'Tokens deletion integration' do

  # All possible scenarios that lead to Kubernetes Tokens needing to be deleted

  let!(:user) { create :user }
  let!(:identity) { create :kubernetes_identity, user: user }
  let!(:project) { create :project }
  let!(:project_membership) { create :project_membership, user: user, project: project }
  let!(:service) { create :service, project: project }
  let!(:cluster) { create :kubernetes_cluster }
  let!(:cluster_to_project_allocation) do
    create :allocation, allocatable: cluster, allocation_receivable: project
  end
  let!(:user_group) { create :kubernetes_group, :not_privileged, :for_user }
  let!(:robot_group) { create :kubernetes_group, :not_privileged, :for_robot }
  let!(:user_group_to_project_allocation) do
    create :allocation, allocatable: user_group, allocation_receivable: project
  end
  let!(:robot_group_to_service_allocation) do
    create :allocation, allocatable: robot_group, allocation_receivable: service
  end
  let!(:user_token_groups) { [ user_group.name ] }
  let!(:user_token) do
    create :user_kubernetes_token, tokenable: identity, project: project, cluster: cluster, groups: user_token_groups
  end
  let!(:robot_token_groups) { [ robot_group.name ] }
  let!(:robot_token) do
    create :robot_kubernetes_token, tokenable: service, cluster: cluster, groups: robot_token_groups
  end

  # Other tokens associated with the project and service, but different everything else
  let!(:other_cluster) { create :kubernetes_cluster }
  let!(:other_cluster_to_project_allocation) do
    create :allocation, allocatable: other_cluster, allocation_receivable: project
  end
  let!(:other_user_group) { create :kubernetes_group, :not_privileged, :for_user }
  let!(:other_robot_group) { create :kubernetes_group, :not_privileged, :for_robot }
  let!(:other_user_group_to_project_allocation) do
    create :allocation, allocatable: other_user_group, allocation_receivable: project
  end
  let!(:other_robot_group_to_service_allocation) do
    create :allocation, allocatable: other_robot_group, allocation_receivable: service
  end
  let!(:other_user_token_groups) { [ other_user_group.name ] }
  let!(:other_user_token) do
    create :user_kubernetes_token, project: project, cluster: other_cluster, groups: other_user_token_groups
  end
  let!(:other_robot_token_groups) { [ other_robot_group.name ] }
  let!(:other_robot_token) do
    create :robot_kubernetes_token, tokenable: service, cluster: other_cluster, groups: other_robot_token_groups
  end

  # Other tokens that belong to different projects/services
  let!(:other_other_user_token) { create :user_kubernetes_token }
  let!(:other_other_robot_token) { create :robot_kubernetes_token }

  def exists model, id
    expect(model.exists?(id: id)).to be true
  end

  def deleted model, id
    expect(model.exists?(id: id)).to be false
  end

  describe 'on user deactivation' do

    class UserActivationTestHarness
      include UserActivation

      def initialize user
        @user = user
      end

      def audit_context
        {}
      end

      def head status
      end
    end

    before do
      expect(UserActivationService).to receive(:deactivate!).with(user)
      UserActivationTestHarness.new(user).handle_user_deactivation_request
    end

    it 'should delete all the user\'s tokens' do
      deleted KubernetesToken, user_token.id
      exists KubernetesToken, robot_token.id

      exists KubernetesToken, other_user_token.id
      exists KubernetesToken, other_robot_token.id

      exists KubernetesToken, other_other_user_token.id
      exists KubernetesToken, other_other_robot_token.id
    end

  end

  describe 'on project deletion' do
    before { project.destroy }

    it 'should delete the associated token(s) only' do
      deleted KubernetesToken, user_token.id
      deleted KubernetesToken, robot_token.id

      deleted KubernetesToken, other_user_token.id
      deleted KubernetesToken, other_robot_token.id

      exists KubernetesToken, other_other_user_token.id
      exists KubernetesToken, other_other_robot_token.id
    end
  end

  describe 'on user\'s project membership deletion' do
    before { project_membership.destroy }

    it 'should delete the user\'s tokens for that project only' do
      deleted KubernetesToken, user_token.id
      exists KubernetesToken, robot_token.id

      exists KubernetesToken, other_user_token.id
      exists KubernetesToken, other_robot_token.id

      exists KubernetesToken, other_other_user_token.id
      exists KubernetesToken, other_other_robot_token.id
    end
  end

  describe 'on service deletion' do
    before { service.destroy }

    it 'should delete the associated token(s) only' do
      exists KubernetesToken, user_token.id
      deleted KubernetesToken, robot_token.id

      exists KubernetesToken, other_user_token.id
      deleted KubernetesToken, other_robot_token.id

      exists KubernetesToken, other_other_user_token.id
      exists KubernetesToken, other_other_robot_token.id
    end
  end

  describe 'on cluster deletion' do
    context 'when no groups have restricted clusters' do
      before { cluster.destroy }

      it 'should delete the associated allocation(s) and token(s) only' do
        deleted Allocation, cluster_to_project_allocation.id
        deleted KubernetesToken, user_token.id
        deleted KubernetesToken, robot_token.id

        exists Allocation, other_cluster_to_project_allocation.id
        exists KubernetesToken, other_user_token.id
        exists KubernetesToken, other_robot_token.id

        exists KubernetesToken, other_other_user_token.id
        exists KubernetesToken, other_other_robot_token.id
      end
    end

    context 'when groups have the cluster in their \'restricted_to_clusters\' list' do
      let!(:c_group_1) do
        create :kubernetes_group, :not_privileged, :for_user, restricted_to_clusters: [ cluster.name ]
      end
      let!(:c_group_1_to_project_allocation) do
        create :allocation, allocatable: c_group_1, allocation_receivable: project
      end
      let!(:c_group_2) do
        create :kubernetes_group, :not_privileged, :for_user, restricted_to_clusters: [ cluster.name, other_cluster.name ]
      end
      let!(:c_group_2_to_project_allocation) do
        create :allocation, allocatable: c_group_2, allocation_receivable: project
      end
      let!(:c_token_1) do
        create :user_kubernetes_token, project: project, cluster: cluster, groups: [ c_group_1.name ]
      end
      let!(:c_token_2) do
        create :user_kubernetes_token, project: project, cluster: other_cluster, groups: [ other_user_group.name, c_group_2.name ]
      end

      before { cluster.destroy }

      it 'should remove the cluster from any groups, deleting the group if needed' do
        deleted Allocation, cluster_to_project_allocation.id

        deleted KubernetesGroup, c_group_1.id
        deleted Allocation, c_group_1_to_project_allocation.id
        exists KubernetesGroup, c_group_2.id
        expect(c_group_2.reload.restricted_to_clusters).to eq [ other_cluster.name ]
        exists Allocation, c_group_2_to_project_allocation.id

        deleted KubernetesToken, c_token_1.id  # Because the associated cluster was deleted

        c_token_2_groups = c_token_2.groups
        expect(c_token_2.reload.groups).to eq c_token_2_groups
      end
    end
  end

  describe 'on cluster-to-project allocation deletion' do
    let!(:c_project) { create(:project) }
    let!(:c_allocation) do
      create :allocation, allocatable: cluster, allocation_receivable: c_project
    end
    let!(:c_token) do
      create :user_kubernetes_token, project: c_project, cluster: cluster
    end

    before { cluster_to_project_allocation.destroy }

    it 'should delete all tokens within that project that are associated with that cluster' do
      deleted KubernetesToken, user_token.id
      deleted KubernetesToken, robot_token.id

      exists KubernetesToken, c_token.id

      exists KubernetesToken, other_user_token.id
      exists KubernetesToken, other_robot_token.id

      exists KubernetesToken, other_other_user_token.id
      exists KubernetesToken, other_other_robot_token.id
    end
  end

  describe 'on group deletion' do
    before { user_group.destroy }

    it 'should remove that group only from tokens that have it' do
      expect(user_token.reload.groups).to be_empty
      expect(robot_token.reload.groups).to eq robot_token_groups

      expect(other_user_token.reload.groups).to eq other_user_token_groups
      expect(other_robot_token.reload.groups).to eq other_robot_token_groups
    end
  end

  describe 'on user-group-to-project allocation deletion' do
    before { user_group_to_project_allocation.destroy }

    it 'should remove that group only from tokens (within the project) that have it' do
      expect(user_token.reload.groups).to be_empty
      expect(robot_token.reload.groups).to eq robot_token_groups

      expect(other_user_token.reload.groups).to eq other_user_token_groups
      expect(other_robot_token.reload.groups).to eq other_robot_token_groups
    end
  end

  describe 'on user-group-to-service allocation deletion' do
    let!(:s_user_group) { create :kubernetes_group, :not_privileged, :for_user }
    let!(:s_user_group_to_service_allocation) do
      create :allocation, allocatable: s_user_group, allocation_receivable: service
    end
    let!(:s_user_token) do
      create :user_kubernetes_token, project: project, cluster: cluster, groups: [s_user_group.name]
    end

    before { s_user_group_to_service_allocation.destroy }

    it 'should remove that group only from robot tokens (within the project) that have it' do
      expect(s_user_token.reload.groups).to be_empty

      expect(user_token.reload.groups).to eq user_token_groups
      expect(robot_token.reload.groups).to eq robot_token_groups

      expect(other_user_token.reload.groups).to eq other_user_token_groups
      expect(other_robot_token.reload.groups).to eq other_robot_token_groups
    end
  end

  describe 'on robot-group-to-project allocation deletion' do
    let!(:p_robot_group) { create :kubernetes_group, :not_privileged, :for_robot }
    let!(:p_robot_group_to_project_allocation) do
      create :allocation, allocatable: p_robot_group, allocation_receivable: project
    end
    let!(:p_robot_token_1) do
      create :robot_kubernetes_token, tokenable: service, cluster: cluster, groups: [p_robot_group.name]
    end

    let!(:other_service) { create :service, project: project }
    let!(:p_robot_token_2) do
      create :robot_kubernetes_token, tokenable: other_service, cluster: cluster, groups: [p_robot_group.name]
    end

    before { p_robot_group_to_project_allocation.destroy }

    it 'should remove that group only from robot tokens (within the project) that have it' do
      expect(p_robot_token_1.reload.groups).to be_empty
      expect(p_robot_token_2.reload.groups).to be_empty

      expect(user_token.reload.groups).to eq user_token_groups
      expect(robot_token.reload.groups).to eq robot_token_groups

      expect(other_user_token.reload.groups).to eq other_user_token_groups
      expect(other_robot_token.reload.groups).to eq other_robot_token_groups
    end
  end

  describe 'on robot-group-to-service allocation deletion' do
    before { robot_group_to_service_allocation.destroy }

    it 'should remove that group only from robot tokens (within the service) that have it' do
      expect(user_token.reload.groups).to eq user_token_groups
      expect(robot_token.reload.groups).to be_empty

      expect(other_user_token.reload.groups).to eq other_user_token_groups
      expect(other_robot_token.reload.groups).to eq other_robot_token_groups
    end
  end

  describe 'on token deletion' do
    before { user_token.destroy }

    it 'none of the associated objects should be deleted' do
      exists Project, project.id
      exists Service, service.id
      exists KubernetesCluster, cluster.id
      exists KubernetesGroup, user_group.id
      exists KubernetesGroup, robot_group.id
    end
  end

end
