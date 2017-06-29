class ProjectSerializer < BaseSerializer
  attributes(
    :id,
    :shortname,
    :name,
    :description,
    :created_at,
    :updated_at
  )

  attributes :members_count

  attribute :cost_centre_code, if: :is_admin_or_project_manager?

  def members_count
    object.memberships.count
  end

  def id
    object.friendly_id
  end

  # Note: `scope` here is actually `current_user` (passed in from controller)
  def is_admin_or_project_manager?
    is_admin? || ProjectManagersService.is_user_a_manager_of_specified_project?(object.id, scope.id)
  end
end
