class User < ApplicationRecord

  validates :name, presence: true
  validates :email, presence: true

  has_many :identities


  def main_identity
    identities.find_by(provider: :keycloak)
  end

end
