class User < ApplicationRecord

  validates :name, presence: true
  validates :email, presence: true

  has_many :identities


  def main_identity
    identity :keycloak
  end

  def identity provider
    identities.find_by provider: provider
  end

end
