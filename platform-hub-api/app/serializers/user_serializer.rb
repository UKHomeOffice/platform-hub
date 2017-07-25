class UserSerializer < BaseSerializer
  attributes :id, :name, :email, :role, :last_seen_at, :is_active

  has_many :identities, if: :is_admin_or_own?

  attribute :enabled_identities do
    object.identities.pluck(:provider)
  end

  has_one :flags, if: :is_admin_or_own?, serializer: UserFlagsSerializer do
    object.ensure_flags
  end

  attributes :is_managerial, :is_technical

  # Note: `scope` here is actually `current_user` (passed in from controller)
  def is_admin_or_own?
    is_admin? || scope.id == object.id
  end
end
