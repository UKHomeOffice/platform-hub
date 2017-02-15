class ProjectMembershipSerializer < ActiveModel::Serializer
  belongs_to :user

  attributes :role
end
