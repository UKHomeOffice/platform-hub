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
    let!(:project) { create :project }
    let!(:group) { create :kubernetes_group, :for_user, allocate_to: project }
    let!(:other_group) { create :kubernetes_group, :for_user, allocate_to: project }

    let(:assigned_groups) do
      [
        group.name,
        other_group.name
      ]
    end

    let!(:token) { create :user_kubernetes_token, project: project, groups: assigned_groups }

    context 'when name has not chaned' do
      it 'should not amend the token\'s groups' do
        group.update! description: 'new description'
        expect(token.reload.groups).to eq assigned_groups
      end
    end

    context 'when name has changed' do
      let(:updated_name) { 'updated-group-name' }

      it 'should amend the token\'s groups' do
        group.update! name: updated_name
        expect(token.reload.groups).to eq [updated_name, other_group.name]
      end
    end
  end

  describe 'after_destroy :handle_destroy' do
    let!(:project) { create :project }
    let!(:group) { create :kubernetes_group, :for_user, allocate_to: project }

    let!(:other_group) { create :kubernetes_group, :for_user, allocate_to: project }

    let(:assigned_groups) do
      [
        group.name,
        other_group.name
      ]
    end

    let!(:token) { create :user_kubernetes_token, project: project, groups: assigned_groups }

    it 'should remove the group from token\'s groups' do
      group.destroy!
      expect(token.reload.groups).to eq [other_group.name]
    end
  end

end
