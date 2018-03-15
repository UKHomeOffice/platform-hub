class KubernetesClusterSerializer < BaseSerializer

  include WithFriendlyIdAttribute

  attributes :name, :aliases, :description

  attribute :aws_account_id, if: :is_admin?
  attribute :aws_region, if: :is_admin?

  attribute :costs_bucket, if: :is_admin?

  attributes :api_url, :ca_cert_encoded

end
