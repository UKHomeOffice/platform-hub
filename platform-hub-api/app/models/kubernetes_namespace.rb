class KubernetesNamespace < ApplicationRecord

  NAME_REGEX = /\A[a-z0-9]([-a-z0-9]*[a-z0-9])?\z/

  include Audited

  audited descriptor_field: :name, associated_field: :service

  belongs_to :service, -> { readonly }
  belongs_to :cluster, -> { readonly }, class_name: KubernetesCluster

  scope :by_service, ->(s) { where(service: s) }
  scope :by_cluster, ->(c) { where(cluster: c) }

  validates :name,
    format: {
      with: NAME_REGEX,
      message: "should consist of lowercase letters, numbers and dashes, and must start and end with an alphanumeric character"
    },
    uniqueness: {
      scope: :cluster_id,
      message: "already exists for the cluster"
    }

  validate :allowed_clusters_only

  protected

  def allowed_clusters_only
    return unless service.present? && cluster.present?

    unless Allocation.exists?(
      allocatable: cluster,
      allocation_receivable: service.project
    )
      errors.add(:cluster_id, "is not allowed for this namespace")
    end
  end

end
