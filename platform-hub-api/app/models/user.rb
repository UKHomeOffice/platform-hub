class User < ApplicationRecord

  include PgSearch
  include Audited

  audited descriptor_field: :email
  has_associated_audits

  before_create :build_flags

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

  has_one :flags,
    class_name: 'UserFlags',
    foreign_key: 'id',
    autosave: true,
    dependent: :destroy

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

  def ensure_flags
    self.flags.presence || self.create_flags!(id: self.id)
  end

  def update_flag name, value
    ensure_flags.send("#{name}=", value)
  end

  def update_flag! name, value
    update_flag name, value
    self.save!
  end

end
