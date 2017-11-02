class ProjectEmbeddedSerializer < BaseSerializer

  include WithFriendlyIdAttribute

  attributes(
    :shortname,
    :name
  )

end
