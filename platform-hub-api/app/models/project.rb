class Project < ApplicationRecord

  include FriendlyId
  include Audited
  include AllocationReceivable

  audited descriptor_field: :shortname
  has_associated_audits

  friendly_id :shortname, :use => :slugged

  allocation_receivable

  attr_readonly :shortname

  scope :by_shortname, -> (value) {
    # Important: the shortname query needs to be case insensitive
    where('lower(shortname) = lower(?)', value)
  }

  validates :shortname,
    presence: true,
    uniqueness: { case_sensitive: false }

  validates :name,
    presence: true

  has_many :memberships,
    class_name: 'ProjectMembership',
    dependent: :destroy

  has_many :members,
    through: :memberships,
    source: :user

  has_many :services,
    dependent: :destroy

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
    class_name: 'KubernetesToken',
    dependent: :destroy

  has_many :docker_repos,
    through: :services,
    dependent: :destroy

  def memberships_ordered_by_users_name
    memberships
      .includes(:user)  # Eager load users for performance
      .joins(:user).order("users.name")  # Order by user name
  end

  private

  def readonly?
    if persisted?
      read_only_attrs = self.class.readonly_attributes.to_a
      if read_only_attrs.any? {|f| send(:"#{f}_changed?")}
        raise ActiveRecord::ReadOnlyRecord, "#{read_only_attrs.join(', ')} can't be modified"
      end
    end
  end

end
