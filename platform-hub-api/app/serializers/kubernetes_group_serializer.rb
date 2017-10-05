class KubernetesGroupSerializer < ActiveModel::Serializer

  include WithFriendlyIdAttribute

  attributes(
    :name,
    :kind,
    :target,
    :description,
    :is_privileged,
    :restricted_to_clusters
  )

end
