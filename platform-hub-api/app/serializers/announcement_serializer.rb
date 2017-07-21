class AnnouncementSerializer < BaseSerializer
  attributes(
    :id,
    :level,
    :original_template_id,
    :template_data,
    :title,
    :text,
    :is_global,
    :is_sticky,
    :publish_at,
    :created_at,
    :updated_at
  )

  attribute :deliver_to, if: :is_admin?
  attribute :status, if: :is_admin?

  attribute :preview, if: -> { object.template_data.present? }  do
    AnnouncementTemplateFormatterService.format object.template_definitions, object.template_data
  end
end
