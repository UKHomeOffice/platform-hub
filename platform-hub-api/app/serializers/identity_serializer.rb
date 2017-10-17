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
      object.tokens, each_serializer: KubernetesTokenSerializer
    )
  end

  attribute :kubernetes_robot_tokens, if: -> { object.kubernetes? && FeatureFlagService.is_enabled?(:kubernetes_tokens) } do
    ActiveModel::Serializer::CollectionSerializer.new(
      object.user.robot_tokens, each_serializer: KubernetesTokenSerializer
    )
  end
end
