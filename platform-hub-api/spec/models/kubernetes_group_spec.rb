require 'rails_helper'

RSpec.describe KubernetesGroup, type: :model do

  describe '#name' do
    it { is_expected.to allow_value('f').for(:name) }
    it { is_expected.to allow_value('foo').for(:name) }
    it { is_expected.to allow_value('foo_bar').for(:name) }
    it { is_expected.to allow_value('foo-bar').for(:name) }
    it { is_expected.to allow_value('foo-1').for(:name) }
    it { is_expected.to allow_value('foo_1').for(:name) }
    it { is_expected.to allow_value('foo:1').for(:name) }

    it { is_expected.not_to allow_value('foo bar').for(:name) }
    it { is_expected.not_to allow_value('foo 1').for(:name) }
    it { is_expected.not_to allow_value('1-foo').for(:name) }
    it { is_expected.not_to allow_value('1').for(:name) }
    it { is_expected.not_to allow_value('-foo').for(:name) }
    it { is_expected.not_to allow_value('_foo').for(:name) }
    it { is_expected.not_to allow_value(':foo').for(:name) }
  end

  describe 'after_update :handle_name_rename' do
    let!(:group) { create :kubernetes_group, :for_user }

    context 'when name has not changed' do
      it 'should not amend the token\'s groups' do
        expect(KubernetesToken).to receive(:update_all_group_rename).never
        group.update! description: 'new description'
      end
    end

    context 'when name has changed' do
      let(:updated_name) { 'updated-group-name' }

      it 'should amend the token\'s groups' do
        expect(KubernetesToken).to receive(:update_all_group_rename).with(group.name, updated_name).once
        group.update! name: updated_name
      end
    end
  end

  describe 'after_destroy :handle_destroy' do
    let!(:group) { create :kubernetes_group, :for_user }

    it 'should remove the group from token\'s groups' do
      expect(KubernetesToken).to receive(:update_all_group_removal).with(group.name).once
      group.destroy!
    end
  end

  describe 'scopes' do

    describe 'with_restricted_cluster' do
      let!(:cluster) { create :kubernetes_cluster }

      subject { KubernetesGroup.with_restricted_cluster(cluster) }

      context 'when no restricted clusters are set' do
        let!(:group) { create :kubernetes_group, restricted_to_clusters: [] }

        it 'should not find any groups' do
          expect(subject.count).to be 0
        end
      end

      context 'when the cluster is set in the restricted list' do
        let!(:group) { create :kubernetes_group, restricted_to_clusters: [ cluster.name ] }

        it 'should find the group' do
          expect(subject.entries).to eq [ group ]
        end
      end

      context 'when a diffrent cluster is set in the restricted list' do
        let!(:other_cluster) { create :kubernetes_cluster }
        let!(:group) { create :kubernetes_group, restricted_to_clusters: [ other_cluster.name ] }

        it 'should not find any groups' do
          expect(subject.count).to be 0
        end
      end
    end

  end

  describe 'custom validations' do

    describe '#cluster_names_exists' do
      let(:existing_cluster_name) { create(:kubernetes_cluster).name }
      let(:not_existing_cluster_name) { 'not-existent-cluster' }

      context 'when restricted_to_clusters is empty' do
        it 'does nothing' do
          expect(KubernetesCluster).to receive(:exists?).never
          group = build :kubernetes_group, restricted_to_clusters: []
          expect(group).to be_valid
        end
      end

      context 'when restricted_to_clusters is not empty' do
        it 'allows setting an existing cluster' do
          group = build :kubernetes_group, restricted_to_clusters: [ existing_cluster_name ]
          expect(group).to be_valid
        end

        it 'raises error when trying to set a cluster that does not exist' do
          expect { create :kubernetes_group, restricted_to_clusters: [ not_existing_cluster_name ] }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Restricted to clusters contain an invalid cluster - 'not-existent-cluster' does not exist"
          )
        end
      end
    end

  end

end
