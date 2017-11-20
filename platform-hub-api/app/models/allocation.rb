class Allocation < ApplicationRecord

  include Audited

  audited associated_field: :allocation_receivable

  after_destroy :handle_destroy

  belongs_to :allocatable, polymorphic: true
  validates :allocatable_type, presence: true
  validates :allocatable_id, presence: true

  belongs_to :allocation_receivable, polymorphic: true
  validates :allocation_receivable_type, presence: true
  validates :allocation_receivable_id, presence: true

  validate :ensure_uniqueness

  scope :by_allocatable, -> (a) { where(allocatable: a) }
  scope :by_allocation_receivable, -> (ar) { where(allocation_receivable: ar) }

  private

  def handle_destroy
    # Note: we assume we are running in a db transaction when this is called
    case self.allocatable_type
    when KubernetesCluster.name
      handle_destroy_for_kubernetes_cluster_allocatable
    when KubernetesGroup.name
      handle_destroy_for_kubernetes_group_allocatable
    else
      Rails.logger.info "Allocation destroyed but no further deletion handling carried out, for allocatable_type: #{self.allocatable_type}"
    end
  end

  def handle_destroy_for_kubernetes_cluster_allocatable
    cluster = self.allocatable
    project = self.allocation_receivable
    project.kubernetes_user_tokens.by_cluster(cluster).each(&:destroy)
    project.services.each do |service|
      service.kubernetes_robot_tokens.by_cluster(cluster).each(&:destroy)
    end
  end

  def handle_destroy_for_kubernetes_group_allocatable
    group = self.allocatable
    case self.allocation_receivable_type
    when Project.name
      project = self.allocation_receivable

      # First handle robot tokens for all services within the project
      project.services.pluck(:id).each do |service_id|
        KubernetesToken.update_all_group_removal group.name, kind: 'robot', service_id: service_id
      end

      # Then handle user tokens for the project
      KubernetesToken.update_all_group_removal group.name, kind: 'user', project_id: project.id
    when Service.name
      service = self.allocation_receivable

      # First handle robot tokens for the service
      KubernetesToken.update_all_group_removal group.name, kind: 'robot', service_id: service.id

      # Then handle user tokens for the project (in case they use a service level group)
      KubernetesToken.update_all_group_removal group.name, kind: 'user', project_id: service.project.id
    end
  end

  def ensure_uniqueness
    if Allocation.where(
      allocatable: self.allocatable,
      allocation_receivable: self.allocation_receivable
    ).exists?
      self.errors[:base] << 'Allocation already exists'
    end
  end

end
