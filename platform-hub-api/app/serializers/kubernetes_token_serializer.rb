class KubernetesTokenSerializer < BaseSerializer
  belongs_to :cluster

  attributes(
    :id,
    :kind,
    :name,
    :uid,
    :groups
  )

  attribute :token do
    object.decrypted_token
  end

  attribute :description, if: -> { object.robot? }

  attribute :expire_privileged_at, if: -> { object.expire_privileged_at.present? }

  has_one :service,
    if: -> { object.robot? && object.tokenable_type == Service.name },
    serializer: ServiceSerializer do
    object.tokenable
  end
end
