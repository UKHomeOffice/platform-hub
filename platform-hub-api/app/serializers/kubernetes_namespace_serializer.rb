class KubernetesNamespaceSerializer < BaseSerializer
  attributes :id, :name, :description

  belongs_to :service

  belongs_to :cluster
end
