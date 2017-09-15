require 'rails_helper'

describe Kubernetes::TokenGroupService, type: :service do

  let(:group_id) { 'acp:all:user:privilege' }
  let(:group_privileged) { true }
  let(:group_description) { 'Some description' }

  let(:group_data) do
    {
      id: group_id,
      privileged: group_privileged,
      description: group_description
    }
  end

  before do
    @groups_config = Kubernetes::TokenGroupService.groups_hash_record
  end

  describe '.create_or_update' do

    context 'given group does not exist' do
      it 'creates a new group configuration' do
        expect {
          subject.create_or_update(group_data)
        }.to change { @groups_config.reload.data.size }.by(1)

        group = @groups_config.data.last
        
        expect(group['id']).to eq group_id
        expect(group['privileged']).to eq group_privileged
        expect(group['description']).to eq group_description
      end
    end

    context 'group already exist' do
      let(:new_group_description) { 'slightly different description' }
      let(:new_group_privileged) { false }
      let(:updated_group_data) do 
        {
          id: group_id,
          privileged: new_group_privileged,
          description: new_group_description
        }
      end

      before do
        subject.create_or_update(group_data)
      end

      it 'updates existing group configuration' do
        expect {
          subject.create_or_update(updated_group_data)
        }.to change { @groups_config.reload.data.size }.by(0)

        existing_group = @groups_config.data.first

        expect(existing_group['id']).to eq group_id
        expect(existing_group['privileged']).to eq new_group_privileged
        expect(existing_group['description']).to eq new_group_description
      end
    end
  end

  describe '.delete' do
    before do
      subject.create_or_update(group_data)
    end

    it 'removes group configuration from the list' do
      expect {
        subject.delete(group_id)
      }.to change { @groups_config.reload.data.size }.by(-1)

      expect(@groups_config.data.size).to eq 0
    end
  end

end
