class KubernetesTokenSerializer < BaseSerializer
  belongs_to :cluster

  attributes(
    :id,
    :kind,
    :name,
    :uid,
    :groups,
    :obfuscated_token
  )

  # - robot tokens: only hub admins and project team members of that service get `token` field at all
  # - user tokens: only the user gets the _full_ token value in the API – hub admins get `XXXXXXXXXXX4567` (i.e. last 4 digits)
  attribute :token, if: 
    -> {(object.robot? && is_admin_or_project_team_member?) || 
        (object.user? && belongs_to_current_user?)} do
    object.decrypted_token
  end

  attribute :description, if: -> { object.robot? }

  attribute :expire_privileged_at, if: -> { object.expire_privileged_at.present? }

  has_one :service,
    if: -> { object.robot? && object.tokenable_type == Service.name },
    serializer: ServiceSerializer do
    object.tokenable
  end

  belongs_to :project, serializer: ProjectEmbeddedSerializer

  # Note: `scope` here is actually `current_user` (passed in from controller)
  def is_admin_or_project_team_member?
    return true if is_admin?
    return false if object.project.blank?
    ProjectMembershipsService.is_user_a_member_of_project?(object.project.id, scope.id)
  end

  def belongs_to_current_user?
    object.owner.id == scope.id
  end
end
