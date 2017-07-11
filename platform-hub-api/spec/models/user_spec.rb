require 'rails_helper'

RSpec.describe User, type: :model do

  before do
    @user = create :user
  end

  describe 'on create' do
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
      expect(user.is_active).to be true
    end

  end

  describe '#deactivate!' do
    it 'sets is_active to false' do
      expect{@user.deactivate!}.to change{@user.is_active}.from(true).to(false)
    end
  end

  describe '#activate!' do
    before do
      @user.deactivate!
    end

    it 'sets is_active to true' do
      expect{@user.activate!}.to change{@user.is_active}.from(false).to(true)
    end
  end

end
