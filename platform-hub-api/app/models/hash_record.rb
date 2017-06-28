class HashRecord < ApplicationRecord

  enum scope: {
    general: 'general',
    kubernetes: 'kubernetes',
    webapp: 'webapp'
  }

  validates :scope,
    presence: true

end
