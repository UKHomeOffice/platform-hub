class PlatformThemeSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :title,
    :description,
    :image_url,
    :colour,
    :created_at,
    :updated_at
  )

  def id
    object.friendly_id
  end
end