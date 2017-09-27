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

  attribute :kubernetes_tokens, if: -> { object.kubernetes? && FeatureFlagService.is_enabled?(:kubernetes_tokens) } do
    ActiveModel::Serializer::CollectionSerializer.new(
      Kubernetes::TokenService.tokens_from_identity_data(object.data)
    )
  end

  attribute :kubernetes_robot_tokens, if: -> { object.kubernetes? && FeatureFlagService.is_enabled?(:kubernetes_tokens) } do
    ActiveModel::Serializer::CollectionSerializer.new(
      Kubernetes::RobotTokenService.get_by_user_id(object.user_id)
    )
  end
end
