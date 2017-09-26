class KubernetesRobotTokenSerializer < KubernetesTokenBaseSerializer
  attributes :name, :description

  attribute :user, if: -> { object.user.present? } do
    {
      id: object.user.id,
      name: object.user.name,
      email: object.user.email
    }
  end
end
