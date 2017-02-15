FactoryGirl.define do
  factory :project_membership do
    project
    user

    factory :project_membership_as_manager do
      role 'manager'
    end
  end
end
