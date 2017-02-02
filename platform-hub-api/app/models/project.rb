class Project < ApplicationRecord

  include FriendlyId

  friendly_id :shortname, :use => :slugged

  validates :shortname,
    presence: true,
    uniqueness: true

  validates :name,
    presence: true

  has_many :memberships,
    class_name: 'ProjectMembership',
    dependent: :delete_all

  has_many :members,
    through: :memberships,
    source: :user

end
