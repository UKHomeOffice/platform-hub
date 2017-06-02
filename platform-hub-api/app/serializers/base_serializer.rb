class BaseSerializer < ActiveModel::Serializer

  # Note: `scope` here is actually `current_user` (passed in from controller)

  def is_admin?
    scope.admin?
  end

end
