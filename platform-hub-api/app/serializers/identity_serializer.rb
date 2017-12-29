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

  has_many :kubernetes_tokens, if: -> { object.kubernetes? && FeatureFlagService.is_enabled?(:kubernetes_tokens) } do
    object
      .tokens
      .includes(:project, :cluster)  # Eager load projects and clusters for performance
      .joins(:project, :cluster).order('"projects"."name" ASC, "kubernetes_clusters"."name" ASC')  # Order by project and cluster names
  end
end
