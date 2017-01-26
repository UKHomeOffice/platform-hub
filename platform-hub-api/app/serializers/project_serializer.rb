class ProjectSerializer < ActiveModel::Serializer
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
end
