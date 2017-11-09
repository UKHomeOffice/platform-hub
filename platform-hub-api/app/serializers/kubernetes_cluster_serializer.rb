class KubernetesClusterSerializer < BaseSerializer

  include WithFriendlyIdAttribute

  attributes :name, :description

end
