require 'rails_helper'

RSpec.describe User, type: :model do

  describe 'on create' do
    before do
      @user = create :user
    end

    it 'initialises the flags accordingly' do
      user = User.find @user.id
      expect(user.flags.present?).to be true

      # We currently assume that all flags are initialised to `false`
      all_flags_are_false = UserFlags.flag_names.all? { |f| !user.flags.send(f) }
      expect(all_flags_are_false).to be true
    end

    it 'user scope fields are true by default' do
      user = User.find @user.id
      expect(user.is_managerial).to be true
      expect(user.is_technical).to be true
    end

  end

end
