class IdentitySerializer < ActiveModel::Serializer
  attributes(
    :provider,
    :external_id,
    :external_username,
    :external_name,
    :external_email,
    :created_at,
    :updated_at
  )
end
