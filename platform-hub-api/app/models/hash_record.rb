class HashRecord < ApplicationRecord

  enum scope: {
    general: 'general',
    webapp: 'webapp',
    contact_lists: 'contact_lists'
  }

  validates :scope,
    presence: true

end
