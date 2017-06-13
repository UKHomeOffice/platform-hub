class KubernetesTokenSerializer < ActiveModel::Serializer
  attributes(
    :cluster,
    :token,
    :uid,
    :groups
  )

  def token
    object.decrypted_token
  end
end
