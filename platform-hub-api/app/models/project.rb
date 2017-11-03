class Project < ApplicationRecord

  include FriendlyId
  include Audited
  include AllocationReceivable

  audited descriptor_field: :shortname
  has_associated_audits

  friendly_id :shortname, :use => :slugged

  allocation_receivable

  def should_generate_new_friendly_id?
    shortname_changed? || super
  end

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

  has_many :services,
    dependent: :delete_all

  has_many :kubernetes_clusters,
    through: :allocations,
    source: :allocatable,
    source_type: 'KubernetesCluster'

  has_many :kubernetes_groups,
    through: :allocations,
    source: :allocatable,
    source_type: 'KubernetesGroup'

  has_many :kubernetes_user_tokens,
    -> { where kind: 'user' },
    class_name: 'KubernetesToken'

end
