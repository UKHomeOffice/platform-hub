class Project < ApplicationRecord

  include FriendlyId
  include Audited

  audited descriptor_field: :shortname
  has_associated_audits

  friendly_id :shortname, :use => :slugged

  validates :shortname,
    presence: true,
    uniqueness: { case_sensitive: false }

  validates :name,
    presence: true

  has_many :memberships,
    class_name: 'ProjectMembership',
    dependent: :delete_all

  has_many :members,
    through: :memberships,
    source: :user

end
