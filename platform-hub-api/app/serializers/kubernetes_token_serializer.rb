class KubernetesTokenSerializer < ActiveModel::Serializer
  attributes(
    :cluster,
    :token, 
    :uid,
    :groups
  )
end
