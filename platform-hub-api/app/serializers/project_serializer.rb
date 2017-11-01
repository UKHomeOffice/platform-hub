class ProjectSerializer < BaseSerializer

  include WithFriendlyIdAttribute

  attributes(
    :shortname,
    :name,
    :description,
    :created_at,
    :updated_at
  )

  attributes :members_count

  attribute :cost_centre_code, if: :is_admin_or_project_manager?

  attribute :members_count do
    object.memberships.count
  end

  # Note: `scope` here is actually `current_user` (passed in from controller)
  def is_admin_or_project_manager?
    is_admin? || ProjectMembershipsService.is_user_a_manager_of_project?(object.id, scope.id)
  end

end
