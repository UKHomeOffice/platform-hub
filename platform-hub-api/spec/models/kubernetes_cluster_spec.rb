require 'rails_helper'

RSpec.describe KubernetesCluster, type: :model do

  describe '#name' do
    it { is_expected.to allow_value('f').for(:name) }
    it { is_expected.to allow_value('foo').for(:name) }
    it { is_expected.to allow_value('foo_bar').for(:name) }
    it { is_expected.to allow_value('foo-bar').for(:name) }
    it { is_expected.to allow_value('foo-1').for(:name) }
    it { is_expected.to allow_value('foo_1').for(:name) }

    it { is_expected.not_to allow_value('foo bar').for(:name) }
    it { is_expected.not_to allow_value('foo 1').for(:name) }
    it { is_expected.not_to allow_value('1-foo').for(:name) }
    it { is_expected.not_to allow_value('1').for(:name) }
    it { is_expected.not_to allow_value('-foo').for(:name) }
    it { is_expected.not_to allow_value('_foo').for(:name) }
  end

  describe '#aws_account_id' do
    it { is_expected.to allow_value('123456789012').for(:aws_account_id) }
    it { is_expected.to allow_value(nil).for(:aws_account_id) }
    it { is_expected.to allow_value('').for(:aws_account_id) }

    it { is_expected.not_to allow_value('123').for(:aws_account_id) }
    it { is_expected.not_to allow_value('1234567890').for(:aws_account_id) }
    it { is_expected.not_to allow_value('1234567890123').for(:aws_account_id) }
    it { is_expected.not_to allow_value('A12345678901').for(:aws_account_id) }
    it { is_expected.not_to allow_value('A').for(:aws_account_id) }

    it 'should be set if aws_region is set' do
      c = build :kubernetes_cluster, aws_account_id: nil, aws_region: nil
      expect(c.valid?).to be true

      c = build :kubernetes_cluster, aws_account_id: 123456789012, aws_region: nil
      expect(c.valid?).to be true

      c = build :kubernetes_cluster, aws_account_id: nil, aws_region: 'foo'
      expect(c.valid?).to be false
      expect(c.errors[:aws_account_id]).to include("can't be blank if AWS region is set")
    end
  end

  describe '#aws_account_id and #aws_region uniqueness' do
    before do
      create :kubernetes_cluster, aws_account_id: nil, aws_region: nil
      create :kubernetes_cluster, aws_account_id: 123456789012, aws_region: nil
      create :kubernetes_cluster, aws_account_id: 234567890123, aws_region: 'foo'
      create :kubernetes_cluster, aws_account_id: 234567890123, aws_region: 'bar'
    end

    it 'should still allow multiple clusters with nil for these attributes' do
      c = build :kubernetes_cluster, aws_account_id: nil, aws_region:  nil
      expect(c.valid?).to be true
      expect(c.save).to be true
    end

    it 'should only allow unique pairs of these attributes' do
      c = build :kubernetes_cluster, aws_account_id: 123456789012, aws_region: nil
      expect(c.valid?).to be false
      expect(c.errors[:aws_account_id]).to include("already has a cluster within the same region")

      c = build :kubernetes_cluster, aws_account_id: 123456789012, aws_region: 'foo'
      expect(c.valid?).to be true
      expect(c.save).to be true

      c = build :kubernetes_cluster, aws_account_id: 234567890123, aws_region: nil
      expect(c.valid?).to be true
      expect(c.save).to be true

      c = build :kubernetes_cluster, aws_account_id: 234567890123, aws_region: 'bar'
      expect(c.valid?).to be false
      expect(c.errors[:aws_account_id]).to include("already has a cluster within the same region")

      c = build :kubernetes_cluster, aws_account_id: 234567890123, aws_region: 'new'
      expect(c.valid?).to be true
      expect(c.save).to be true
    end
  end

end
