class Identity < ApplicationRecord

  enum provider: {
    keycloak: 'keycloak',
    github: 'github'
  }

  belongs_to :user
  validates :user_id, presence: true

  validates :provider,
    presence: true,
    uniqueness: { scope: :user_id }

  validates :external_id, presence: true

end
