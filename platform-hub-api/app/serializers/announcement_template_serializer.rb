class AnnouncementTemplateSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :shortname,
    :description,
    :created_at,
    :updated_at
  )

  attribute :spec
end
