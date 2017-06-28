require 'rails_helper'

describe FeatureFlagService, type: :service do

  let(:secret_key_base) { SecureRandom.hex(64) }
  let(:string) { 'my secret string' }

  before do
    @flag1 = 'some_feature'
    @state1 = true
    @flag2 = 'other_feature'
    @state2 = false

    create(:feature_flags_hash_record,
      data: {
	@flag1 => @state1,
	@flag2 => @state2
      }
    )
  end

  describe '.all' do
    it 'returns all defined feature flags' do
      res = subject.all
      expect(res.size).to be 2
      expect(res[@flag1]).to be @state1
      expect(res[@flag2]).to be @state2
    end
  end

  describe '.create_or_update' do
    context 'when flag already exists' do
      it 'updates its value' do
	subject.create_or_update(@flag1, !@state1)
	expect(subject.all.size).to be 2
	expect(subject.all[@flag1]).to be !@state1
      end
    end

    context 'when flag doesnt exist yet' do
      let(:flag) { 'new-flag' }
      let(:state) { true }
      it 'creates a new flag entry' do
	expect(subject.all.size).to be 2
	subject.create_or_update(flag, state)
	expect(subject.all.size).to be 3
	expect(subject.all[flag]).to be state
      end
    end
  end

  describe '.delete' do
    it 'removes flag from the list' do
      expect(subject.all.size).to be 2
      subject.delete(@flag1)
      expect(subject.all.size).to be 1
    end
  end

  describe '.is_enabled?' do
    it 'returns true for enabled features' do
      expect(subject.is_enabled?(@flag1)).to be true
    end

    it 'returns false for disabled features' do
      expect(subject.is_enabled?(@flag2)).to be false
    end

    it 'returns false for non-existing features' do
      expect(subject.is_enabled?(:unknown_feature)).to be false
    end
  end

  describe 'private methods' do
    describe '.feature_flags' do
      it 'finds or creates general hash record by id' do
	expect(HashRecord).to receive_message_chain(:general, :find_or_create_by!).with(id: 'feature_flags')
	subject.send(:feature_flags)
      end
    end
  end

end
