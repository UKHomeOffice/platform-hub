require 'rails_helper'

RSpec.describe KubernetesToken, type: :model do
  include_context 'time helpers'

  let(:token) { SecureRandom.uuid }
  let(:another_token) { SecureRandom.uuid }

  before do
    @t = build :user_kubernetes_token, token: token
  end

  describe '#new' do
    it 'encrypts plain token upon creation of a new object' do
      expect(@t.token).to match(/--[\p{Alnum}]{40}/)
      expect(@t.token).to_not eq token
      expect(@t.decrypted_token).to eq token
    end

    it 'encrypts token on the fly when new value is set' do
      @t.token = another_token
      expect(@t.token).to match(/--[\p{Alnum}]{40}/)
      expect(@t.token).to_not eq another_token
      expect(@t.decrypted_token).to eq another_token
    end

    context 'for invalid token length' do
      before do
        @t = build :user_kubernetes_token, token: 'too-short'
      end

      it 'length of the token validation will fail' do
        expect(@t.valid?).to be false
        expect(@t.errors.full_messages).to include "Token is the wrong length (should be 36 characters)"
      end
    end

    context 'for invalid uid length' do
      before do
        @t = build :user_kubernetes_token, uid: 'too-short'
      end

      it 'length of the token validation will fail' do
        expect(@t.valid?).to be false
        expect(@t.errors.full_messages).to include "Uid is the wrong length (should be 36 characters)"
      end
    end

    context 'for invalid name not following regex pattern' do
      before do
        @t = build :user_kubernetes_token, name: 'name with spaces'
      end

      it 'pattern validation will fail' do
        expect(@t.valid?).to be false
        expect(@t.errors.full_messages).to include(
          "Name must start with letter and can only contain letters, numbers, underscores, dashes, dots and @"
        )
      end
    end

    context 'for blank cluster' do
      it 'cluster validation will fail' do
        expect { create(:user_kubernetes_token, cluster: nil) }.to raise_error(
          ActiveRecord::RecordInvalid, "Validation failed: Cluster can't be blank"
        )
      end
    end

    context 'before save' do
      before do
        @t = create :user_kubernetes_token, name: 'Camel-Case-Name'
      end

      it 'downcases token name' do
        expect(@t.name).to eq 'camel-case-name'
      end
    end
  end

  describe '#name' do
    it { is_expected.to allow_value('f').for(:name) }
    it { is_expected.to allow_value('foo').for(:name) }
    it { is_expected.to allow_value('foo_bar').for(:name) }
    it { is_expected.to allow_value('foo-bar').for(:name) }
    it { is_expected.to allow_value('foo-1').for(:name) }
    it { is_expected.to allow_value('foo_1').for(:name) }
    it { is_expected.to allow_value('foo.1').for(:name) }
    it { is_expected.to allow_value('foo@example.org').for(:name) }

    it { is_expected.not_to allow_value('foo bar').for(:name) }
    it { is_expected.not_to allow_value('foo 1').for(:name) }
    it { is_expected.not_to allow_value('1 foo').for(:name) }
    it { is_expected.not_to allow_value('foo#').for(:name) }
    it { is_expected.not_to allow_value('-foo').for(:name) }
    it { is_expected.not_to allow_value('_foo').for(:name) }
  end

  describe '#decrypted_token' do
    it 'returns decrypted kubernetes token value' do
      expect(@t.decrypted_token).to eq token
    end
  end

  describe '#groups=' do
    context 'for comma separated list of groups' do
      it 'parses the string and assigns groups to kubernetes token' do
        @t.groups = "group1,group2,   group3"
        expect(@t.groups.size).to eq 3
        expect(@t.groups).to match_array ['group1', 'group2', 'group3']
      end
    end

    context 'for groups as array' do
      it 'assigns groups to token' do
        @t.groups = ['group1','group2']
        expect(@t.groups.size).to eq 2
        expect(@t.groups).to match_array ['group1', 'group2']
      end
    end
  end

  describe '#privileged?' do
    it 'returns false for object with expire_privileged_at set to nil' do
      @t.expire_privileged_at = nil
      expect(@t.privileged?).to be false
    end

    it 'returns true for object with expire_privileged_at set to a specifid date' do
      @t.expire_privileged_at = 10.minutes.from_now
      expect(@t.privileged?).to be true
    end
  end

  describe '#escalate' do
    let(:privileged_group) { create(:kubernetes_group, :privileged, :for_user) }

    it 'escalates token for given group and expiration time' do
      expect(@t.escalate(privileged_group.name, 2000)).to be true
      expect(@t.privileged?).to be true
      expect(@t.groups).to include privileged_group.name
      expect(@t.expire_privileged_at).to eq 2000.seconds.from_now
    end

    context 'for invalid token' do
      before do
        @t.uid = nil
      end

      it 'returns false if escalated record not valid' do
        expect(@t.escalate(privileged_group.name)).to eq false
      end
    end

    context 'when expiration time in seconds is not provided' do
      it 'sets expiration to 600 sec by default' do
        @t.escalate privileged_group.name
        expect(@t.privileged?).to be true
        expect(@t.groups).to include privileged_group.name
        expect(@t.expire_privileged_at).to eq 600.seconds.from_now
      end
    end

    context 'when exp time in seconds is lower than PRIVILEGED_GROUP_MAX_EXPIRATION_SECONDS' do
      it 'sets the value as passed number of seconds from now' do
        move_time_to now
        @t.escalate privileged_group.name, 180
        expect(@t.expire_privileged_at).to eq 180.seconds.from_now
      end
    end

    context 'when exp time in seconds is greater than PRIVILEGED_GROUP_MAX_EXPIRATION_SECONDS' do
      it 'limits and sets value as PRIVILEGED_GROUP_MAX_EXPIRATION_SECONDS from now' do
        move_time_to now
        @t.escalate privileged_group.name, KubernetesToken::PRIVILEGED_GROUP_MAX_EXPIRATION_SECONDS + 10
        expect(@t.expire_privileged_at).to eq (KubernetesToken::PRIVILEGED_GROUP_MAX_EXPIRATION_SECONDS).seconds.from_now
      end
    end
  end

  describe '#deescalate' do
    before do
      @privileged_group = create :kubernetes_group, :privileged
      @t.escalate @privileged_group.name, 2000
    end

    it 'deescalates token by removing all privileged groups and setting expiration time to nil' do
      expect(@t.deescalate).to be true
      expect(@t.privileged?).to be false
      expect(@t.groups).to_not include @privileged_group.name
      expect(@t.expire_privileged_at).to be nil
    end

    context 'for invalid token' do
      before do
        @t.uid = nil
      end

      it 'returns false if deescalated record not valid' do
        expect(@t.deescalate).to eq false
      end
    end
  end

  describe '#owner' do
    context 'for user kubernetes token' do
      it 'returns user via kubernetes identity' do
        expect(@t.tokenable_type).to eq 'Identity'
        expect(@t.owner).to eq @t.tokenable.user
      end
    end

    context 'for robot kubernetes token' do
      before do
        @t = build :robot_kubernetes_token, token: token
      end

      it 'doesn\'t have an owner' do
        expect(@t.owner).to be_nil
      end
    end
  end

  describe 'persisted token attributes read-only' do
    before do
      @t = create :user_kubernetes_token
    end

    describe '#token' do
      it 'does not allow to update token' do
        expect { @t.update_attributes(token: SecureRandom.uuid) }.to raise_error(
          ActiveRecord::ReadOnlyRecord, "token, name, uid, kind, cluster_id, project_id can't be modified"
        )
      end
    end

    describe '#uid' do
      it 'does not allow to update uid' do
        expect { @t.update_attributes(uid: SecureRandom.uuid) }.to raise_error(
          ActiveRecord::ReadOnlyRecord, "token, name, uid, kind, cluster_id, project_id can't be modified"
        )
      end
    end

    describe '#name' do
      it 'does not allow to update name' do
        expect { @t.update_attributes(name: 'new_name') }.to raise_error(
          ActiveRecord::ReadOnlyRecord, "token, name, uid, kind, cluster_id, project_id can't be modified"
        )
      end
    end

    describe '#kind' do
      let(:service) { create :service }
      let(:cluster) { create :kubernetes_cluster, allocate_to: service.project }

      it 'does not allow to update kind' do
        expect { @t.update_attributes(kind: 'robot', tokenable: service, cluster: cluster, description: 'blah', groups: []) }.to raise_error(
          ActiveRecord::ReadOnlyRecord, "token, name, uid, kind, cluster_id, project_id can't be modified"
        )
      end
    end

    describe '#project' do
      let(:new_project) { create :project }

      it 'does not allow to update project' do
        expect { @t.update_attributes(project: new_project) }.to raise_error(
          ActiveRecord::ReadOnlyRecord, "token, name, uid, kind, cluster_id, project_id can't be modified"
        )
      end
    end

    describe '#cluster' do
      let(:new_cluster) { create :kubernetes_cluster }

      it 'does not allow to update cluster' do
        expect { @t.update_attributes(cluster: new_cluster) }.to raise_error(
          ActiveRecord::ReadOnlyRecord, "token, name, uid, kind, cluster_id, project_id can't be modified"
        )
      end
    end
  end

  describe '#set_project callback' do

    context 'for user token' do
      it 'is not called' do
        token = build :user_kubernetes_token
        expect(token).to receive(:set_project).never
        token.save!
      end
    end

    context 'for robot token' do
      let(:project) { create :project }
      let(:other_project) { create :project }
      let(:service) { create :service, project: project }

      it 'sets the project from the service, even if another project is provided' do
        token = build :robot_kubernetes_token, tokenable: service, project: other_project
        expect(token).to receive(:set_project).and_call_original
        token.save!
        expect(token.project).to eq project
      end
    end

  end

  describe 'custom validations' do

    describe '#tokenable_set' do
      context 'for robot token' do
        let(:project) { create :project }
        let(:cluster) { create :kubernetes_cluster, allocate_to: project }
        let(:identity) { create :identity }

        it 'raises error on tokenable_type other than User' do
          expect { create :robot_kubernetes_token, tokenable: identity, project: project, cluster: cluster }.to raise_error(
            ActiveRecord::RecordInvalid, "Validation failed: Tokenable type must be `Service` for robot token"
          )
          expect(KubernetesToken.count).to eq 0
        end
      end

      context 'for user token' do
        let(:service) { create :service }

        it 'raises error on tokenable_type other than Identity' do
          expect { create :user_kubernetes_token, tokenable: service }.to raise_error(
            ActiveRecord::RecordInvalid, "Validation failed: Tokenable type must be `Identity` for user token"
          )
          expect(KubernetesToken.count).to eq 0
        end
      end

      it 'raises error on blank tokenable_id' do
        t = build :user_kubernetes_token, tokenable: nil
        expect(t.valid?).to eq false
        expect(t.errors.full_messages).to include 'Tokenable must be set for token'
      end
    end

    describe '#token_must_not_be_blank' do
      it 'raises error on blank token value' do
        expect { create :user_kubernetes_token, token: '' }.to raise_error(
          ActiveRecord::RecordInvalid, "Validation failed: Token can't be blank"
        )
        expect(KubernetesToken.count).to eq 0
      end
    end

    describe '#token_must_be_of_expected_length' do
      it 'raises error on token value shorter than given TOKEN_LENGTH' do
        expect { create :user_kubernetes_token, token: 'blah' }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Token is the wrong length (should be #{KubernetesToken::TOKEN_LENGTH} characters)"
        )
        expect(KubernetesToken.count).to eq 0
      end
    end

    describe '#one_user_token_per_cluster' do
      before do
        @t.save! # first entry built in before block at the top
      end

      it 'raises error on more than one token per user per cluster' do
        expect(KubernetesToken.count).to eq 1
        expect { create :user_kubernetes_token, cluster: @t.cluster, tokenable: @t.tokenable }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: User can have only one user token per cluster"
        )
        expect(KubernetesToken.count).to eq 1
      end
    end

    describe '#robot_name_unique_for_given_cluster' do
      before do
        @robot_token = create :robot_kubernetes_token
      end

      it 'raises error on duplicate robot name for a given cluster' do
        expect { create :robot_kubernetes_token, tokenable: @robot_token.tokenable, cluster: @robot_token.cluster, name: @robot_token.name, groups: @robot_token.groups }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Name must be unique for each robot token within a cluster"
        )
        expect(KubernetesToken.robot.count).to eq 1
      end

      context 'when updating robot token attributes different than cluster or name' do
        it 'should not raise validation errors' do
          expect { @robot_token.update_attributes!(description: 'a new desc') }.to_not raise_error
          expect(KubernetesToken.robot.count).to eq 1
        end
      end
    end

    describe '#robot_description_present' do
      it 'raises error on missing robot token description' do
        expect { create :robot_kubernetes_token, description: '' }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Description can't be blank"
        )
      end
    end

    describe '#group_names_exist' do
      let(:existing_group_name) { create(:kubernetes_group).name }
      let(:not_existing_group_name) { 'non-existent-group' }

      it 'still allows setting empty groups' do
        token = build :user_kubernetes_token, groups: []
        expect(token).to be_valid
      end

      it 'allows setting an existing group' do
        token = build :user_kubernetes_token, groups: [ existing_group_name ]
        expect(token).to be_valid
      end

      it 'raises error when trying to set a group that does not exist' do
        expect { create :user_kubernetes_token, groups: [ existing_group_name, not_existing_group_name ] }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Groups contain an invalid group - 'non-existent-group' does not exist"
        )
      end
    end

    describe '#allowed_clusters_only' do

      context 'for robot token' do

        let!(:project) { create :project }
        let!(:service) { create :service, project: project }
        let!(:allocated_cluster) { create :kubernetes_cluster, allocate_to: project }
        let!(:unallocated_cluster) { create :kubernetes_cluster }
        let!(:other_allocated_cluster) { create :kubernetes_cluster, allocate_to: create(:project) }

        it 'allows using the allocated cluster' do
          token = build :robot_kubernetes_token, tokenable: service, cluster: allocated_cluster
          expect(token).to be_valid
        end

        it 'raises error when using unallocated cluster' do
          expect { create :robot_kubernetes_token, tokenable: service, cluster: unallocated_cluster }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Cluster is not allowed for this token"
          )
        end

        it 'raises error when using other allocated cluster' do
          expect { create :robot_kubernetes_token, tokenable: service, cluster: other_allocated_cluster }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Cluster is not allowed for this token"
          )
        end

      end

    end

    describe '#allowed_groups_only' do

      context 'for robot token' do

        let!(:project) { create :project }
        let!(:service) { create :service, project: project }
        let!(:cluster) { create :kubernetes_cluster, allocate_to: project }
        let!(:other_cluster) { create :kubernetes_cluster, allocate_to: project }

        def expect_allowed group
          token = build :robot_kubernetes_token, tokenable: service, cluster: cluster, groups: [ group.name ]
          expect(token).to be_valid
        end

        def expect_error group
          expect {
            create :robot_kubernetes_token, tokenable: service, cluster: cluster, groups: [ group.name ]
          }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Groups contain an invalid group - '#{group.name}' is not allowed for this token"
          )
        end

        context 'for an allocated not privileged user group with no cluster restrictions' do
          let(:group) { create :kubernetes_group, :not_privileged, :for_user, allocate_to: service, restricted_to_clusters: [] }

          it 'should not allow group to be set' do
            expect_error group
          end
        end

        context 'for an allocated not privileged robot group with no cluster restrictions' do
          let(:group) { create :kubernetes_group, :not_privileged, :for_robot, allocate_to: service, restricted_to_clusters: [] }

          it 'should allow the group to be set' do
            expect_allowed group
          end
        end

        context 'for an allocated not privileged robot group restricted to same cluster' do
          let(:group) { create :kubernetes_group, :not_privileged, :for_robot, allocate_to: service, restricted_to_clusters: [ cluster.name ] }

          it 'should allow the group to be set' do
            expect_allowed group
          end
        end

        context 'for an allocated not privileged robot group restricted to other cluster' do
          let(:group) { create :kubernetes_group, :not_privileged, :for_robot, allocate_to: service, restricted_to_clusters: [ other_cluster.name ] }

          it 'should not allow group to be set' do
            expect_error group
          end
        end

        context 'for an allocated privileged robot group with no cluster restrictions' do
          let(:group) { create :kubernetes_group, :privileged, :for_robot, restricted_to_clusters: [ ] }

          it 'should not allow group to be set' do
            expect_error group
          end
        end

        context 'for an unallocated not privileged robot group with no cluster restrictions' do
          let(:group) { create :kubernetes_group, :not_privileged, :for_robot, restricted_to_clusters: [] }

          it 'should not allow group to be set' do
            expect_error group
          end
        end

        context 'for an unallocated not privileged group restricted to cluster' do
          let(:group) { create :kubernetes_group, :not_privileged, :for_robot, restricted_to_clusters: [ cluster.name ] }

          it 'should not allow group to be set' do
            expect_error group
          end
        end

        context 'for an unallocated privileged group with no cluster restrictions' do
          let(:group) { create :kubernetes_group, :privileged, :for_robot, restricted_to_clusters: [] }

          it 'should not allow group to be set' do
            expect_error group
          end
        end

        context 'for an allocated not privileged group with no cluster restrictions that has been allocated to the project' do
          let(:group) { create :kubernetes_group, :not_privileged, :for_robot, allocate_to: service.project, restricted_to_clusters: [] }

          it 'should allow the group to be set' do
            expect_allowed group
          end
        end

      end

    end

  end

end
