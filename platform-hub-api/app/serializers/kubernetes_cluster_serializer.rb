class KubernetesClusterSerializer < BaseSerializer

  include WithFriendlyIdAttribute

  attributes :name, :description

  attribute :aws_account_id, if: :is_admin?

end
