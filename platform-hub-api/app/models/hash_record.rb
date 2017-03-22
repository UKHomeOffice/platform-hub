class HashRecord < ApplicationRecord

  include Audited

  audited descriptor_field: :id

  enum scope: {
    general: 'general'
  }

end
