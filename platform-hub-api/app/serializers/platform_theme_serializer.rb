class PlatformThemeSerializer < BaseSerializer

  include WithFriendlyIdAttribute

  attributes(
    :title,
    :description,
    :image_url,
    :colour,
    :resources,
    :created_at,
    :updated_at
  )

  def resources
    object.resources || []
  end

end
