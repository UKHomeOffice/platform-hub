class IdentitySerializer < BaseSerializer
  attributes(
    :provider,
    :external_id,
    :external_username,
    :external_name,
    :external_email,
    :created_at,
    :updated_at
  )

  attribute :kubernetes_tokens, if: -> { object.kubernetes? } do
    ActiveModel::Serializer::CollectionSerializer.new(
      Kubernetes::TokenService.tokens_from_identity_data(object.data)
    )
  end
end
