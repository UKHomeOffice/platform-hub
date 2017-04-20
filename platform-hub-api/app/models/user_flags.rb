class UserFlags < ApplicationRecord

  NON_FLAG_FIELDS = [
    'id',
    'created_at',
    'updated_at'
  ]

  belongs_to :user,
    foreign_key: 'id',
    inverse_of: :flags

  def self.flag_names
    @flag_names ||= (UserFlags.columns.map(&:name) - NON_FLAG_FIELDS)
  end

end
