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
  end

end
