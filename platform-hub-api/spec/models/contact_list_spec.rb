require 'rails_helper'

RSpec.describe ContactList, type: :model do

  describe '#id' do
    it { is_expected.to allow_value('f').for(:id) }
    it { is_expected.to allow_value('foo').for(:id) }
    it { is_expected.to allow_value('foo_bar').for(:id) }
    it { is_expected.to allow_value('foo-bar').for(:id) }
    it { is_expected.to allow_value('foo-1').for(:id) }
    it { is_expected.to allow_value('foo_1').for(:id) }

    it { is_expected.not_to allow_value('foo bar').for(:id) }
    it { is_expected.not_to allow_value('foo 1').for(:id) }
    it { is_expected.not_to allow_value('1-foo').for(:id) }
    it { is_expected.not_to allow_value('1').for(:id) }
    it { is_expected.not_to allow_value('-foo').for(:id) }
    it { is_expected.not_to allow_value('_foo').for(:id) }
  end

end
