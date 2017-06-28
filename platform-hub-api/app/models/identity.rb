class Identity < ApplicationRecord

  include Audited

  audited descriptor_field: :provider, associated_field: :user

  enum provider: {
    keycloak: 'keycloak',
    github: 'github',
    kubernetes: 'kubernetes'
  }

  belongs_to :user
  validates :user_id, presence: true

  validates :provider,
    presence: true,
    uniqueness: { scope: :user_id }

  validates :external_id, presence: true

end
