class User < ApplicationRecord

  include PgSearch
  include Audited

  audited descriptor_field: :email
  has_associated_audits

  acts_as_reader

  before_create :build_flags

  enum role: {
    admin: 'admin',
    limited_admin: 'limited_admin'
  }

  validates :name, presence: true
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false }

  has_many :identities,
    dependent: :destroy

  has_many :memberships,
    class_name: 'ProjectMembership',
    dependent: :destroy

  has_many :projects, through: :memberships

  has_one :flags,
    class_name: 'UserFlags',
    foreign_key: 'id',
    autosave: true,
    dependent: :destroy

  pg_search_scope :search,
    against: {
      name: 'A',
      email: 'B'
    },
    using: {
      tsearch: { prefix: true },
      trigram: {}
    }

  scope :active, -> { where(is_active: true) }

  def main_identity
    identity :keycloak
  end

  def github_identity
    identity :github
  end

  def kubernetes_identity
    identity :kubernetes
  end

  def ecr_identity
    identity :ecr
  end

  def identity provider
    identities.find_by provider: provider
  end

  def make_admin!
    self.admin!
  end

  def revoke_admin!
    if admin?
      self.role = nil
      self.save!
    end
  end

  def make_limited_admin!
    self.limited_admin!
  end

  def revoke_limited_admin!
    if limited_admin?
      self.role = nil
      self.save!
    end
  end

  def deactivate!
    self.is_active = false
    self.save!
  end

  def activate!
    self.is_active = true
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
