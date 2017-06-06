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

  def members_count
    object.memberships.count
  end

  def id
    object.friendly_id
  end
end
