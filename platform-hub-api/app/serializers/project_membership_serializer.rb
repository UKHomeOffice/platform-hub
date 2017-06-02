class ProjectMembershipSerializer < BaseSerializer
  belongs_to :user

  attributes :role
end
