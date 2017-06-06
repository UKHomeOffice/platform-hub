class AnnouncementSerializer < BaseSerializer
  attributes(
    :id,
    :level,
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
end
