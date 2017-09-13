class KubernetesTokenSerializer < KubernetesTokenBaseSerializer
  attribute :expire_privileged_at, if: -> { object.expire_privileged_at.present? }  do
    object.expire_privileged_at
  end
end
