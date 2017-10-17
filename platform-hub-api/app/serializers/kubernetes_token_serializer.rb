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

  attribute :user, if: -> { object.user.present? } do
    {
      id: object.user.id,
      name: object.user.name,
      email: object.user.email
    }
  end

  attribute :description, if: -> { object.robot? }

  attribute :expire_privileged_at, if: -> { object.expire_privileged_at.present? }
end
