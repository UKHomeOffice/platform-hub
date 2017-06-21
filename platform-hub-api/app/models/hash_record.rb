class HashRecord < ApplicationRecord

  enum scope: {
    general: 'general',
    webapp: 'webapp'
  }

  validates :scope,
    presence: true

end
