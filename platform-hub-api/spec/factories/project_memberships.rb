FactoryGirl.define do
  factory :project_membership do
    project
    user

    factory :project_membership_as_admin do
      role 'admin'
    end
  end
end
