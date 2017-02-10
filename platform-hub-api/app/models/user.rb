class User < ApplicationRecord

  include PgSearch
  include Audited

  audited descriptor_field: :email
  has_associated_audits

  enum role: {
    admin: 'admin'
  }

  validates :name, presence: true
  validates :email, presence: true

  has_many :identities

  has_many :memberships,
    class_name: 'ProjectMembership',
    dependent: :delete_all

  has_many :projects, through: :memberships

  pg_search_scope :search,
    :against => :name,
    :using => :trigram


  def main_identity
    identity :keycloak
  end

  def identity provider
    identities.find_by provider: provider
  end

  def make_admin!
    self.admin!
  end

  def revoke_admin!
    self.role = nil
    self.save!
  end

end
