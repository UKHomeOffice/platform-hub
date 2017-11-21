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

end
