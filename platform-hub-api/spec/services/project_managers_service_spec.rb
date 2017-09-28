require 'rails_helper'

describe ProjectManagersService, type: :service do

  let!(:project_1) { create :project }
  let!(:project_2) { create :project }
  let!(:project_3) { create :project }

  let!(:user_1) { create :user }
  let!(:user_2) { create :user }
  let!(:user_3) { create :user }

  before do
    create :project_membership_as_manager,
      project: project_1,
      user: user_1
    create :project_membership,
      project: project_1,
      user: user_2

    create :project_membership,
      project: project_2,
      user: user_1
    create :project_membership_as_manager,
      project: project_2,
      user: user_2

    create :project_membership_as_manager,
      project: project_3,
      user: user_2
    create :project_membership,
      project: project_3,
      user: user_3
  end

  describe '.is_user_a_manager_of_project?' do

    let :mappings do
      {
        [ project_1.id, user_1.id ] => true,
        [ project_1.id, user_2.id ] => false,
        [ project_1.id, user_3.id ] => false,
        [ project_2.id, user_1.id ] => false,
        [ project_2.id, user_2.id ] => true,
        [ project_2.id, user_3.id ] => false,
        [ project_3.id, user_1.id ] => false,
        [ project_3.id, user_2.id ] => true,
        [ project_3.id, user_3.id ] => false
      }
    end

    it 'should only return true for actual project managers' do
      mappings.each do |((p_id, u_id), result)|
        expect(
          subject.is_user_a_manager_of_project?(p_id, u_id)
        ).to be result
      end
    end

  end

  describe '.is_user_a_manager_of_any_project?' do

    it 'should only return true if user is a manager of any project' do
      expect(
        subject.is_user_a_manager_of_any_project?(user_1.id)
      ).to be true

      expect(
        subject.is_user_a_manager_of_any_project?(user_2.id)
      ).to be true

      expect(
        subject.is_user_a_manager_of_any_project?(user_3.id)
      ).to be false
    end

  end

  describe '.is_user_a_manager_of_a_common_project?' do

    let :mappings do
      {
        [ user_1, user_2 ] => true,
        [ user_1, user_3 ] => false,
        [ user_2, user_1 ] => true,
        [ user_2, user_3 ] => true,
        [ user_3, user_1 ] => false,
        [ user_3, user_2 ] => false,
      }
    end

    it 'should only return true for cases where the two users share a project and the first user is a manager of any of those projects' do
      mappings.each do |((user, target_user), result)|
        expect(
          subject.is_user_a_manager_of_a_common_project?(user, target_user)
        ).to be result
      end
    end

  end

end
