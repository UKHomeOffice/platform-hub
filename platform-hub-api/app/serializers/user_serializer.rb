class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :role, :last_seen_at

  # Note: `scope` here is actually `current_user` (passed in from controller)
  has_many :identities, if: -> { scope.admin? || scope.id == object.id }

  attributes :enabled_identities

  def enabled_identities
    object.identities.pluck(:provider)
  end
end
