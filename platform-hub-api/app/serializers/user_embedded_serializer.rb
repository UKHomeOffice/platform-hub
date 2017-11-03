class UserEmbeddedSerializer < BaseSerializer
  attributes(
    :id,
    :name,
    :email,
    :is_active,
    :is_managerial,
    :is_technical
  )
end
