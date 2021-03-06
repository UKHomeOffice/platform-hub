class KubernetesGroup < ApplicationRecord

  NAME_REGEX = /\A[a-zA-Z][\w:-]*\z/

  include PgSearch
  include Audited
  include FriendlyId
  include Allocatable

  audited descriptor_field: :name

  friendly_id :name

  allocatable

  after_update :handle_name_rename
  after_destroy :handle_destroy

  validates :name,
    presence: true,
    uniqueness: true,
    format: {
      with: NAME_REGEX,
      message: "should consist of letters, numbers, underscores, dashes and colons (starting with a letter)"
    }

  validates :description,
    presence: true

  enum kind: {
    clusterwide: 'clusterwide',
    namespace: 'namespace'
  }
  validates :kind, presence: true

  enum target: {
    user: 'user',
    robot: 'robot'
  }
  validates :target, presence: true

  validate :cluster_names_exists

  scope :by_kind, -> kind { where(kind: kind) }

  scope :by_target, -> target { where(target: target) }

  scope :privileged, -> { where(is_privileged: true) }
  scope :not_privileged, -> { where.not(is_privileged: true) }

  scope :with_restricted_cluster, -> (c) {
    where("restricted_to_clusters @> ARRAY[?]::varchar[]", Array(c.name))
  }

  pg_search_scope :search,
    against: {
      name: 'A',
      description: 'B'
    },
    using: {
      tsearch: { prefix: true },
      trigram: {}
    }

  def self.privileged_names
    privileged.pluck(:name)
  end

  def self.update_all_cluster_removal cluster
    # Note: we assume we are running in a db transaction when this is called
    KubernetesGroup.with_restricted_cluster(cluster).each do |group|
      group.restricted_to_clusters.delete(cluster.name)

      if group.restricted_to_clusters.empty?
        # If we've just emptied this group out then we need to delete it!
        # (Since now it will be allwowed for all clusters)
        group.destroy
      else
        group.save!
      end
    end
  end

  private

  def handle_name_rename
    if self.name_changed?
      KubernetesToken.update_all_group_rename self.name_was, self.name
    end
  end

  def handle_destroy
    KubernetesToken.update_all_group_removal self.name
  end

  def cluster_names_exists
    Array(self.restricted_to_clusters).each do |name|
      unless KubernetesCluster.exists? name: name
        errors.add(:restricted_to_clusters, "contain an invalid cluster - '#{name}' does not exist")
      end
    end
  end

end
