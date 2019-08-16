class Service < ApplicationRecord

  include Audited
  include AllocationReceivable

  audited descriptor_field: :name, associated_field: :project

  allocation_receivable

  validates :name,
    presence: true

  validates :description,
    presence: true

  belongs_to :project
  validates :project_id, presence: true

  has_many :kubernetes_groups,
    through: :allocations,
    source: :allocatable,
    source_type: 'KubernetesGroup'

  has_many :kubernetes_robot_tokens,
    -> { where kind: 'robot' },
    as: :tokenable,
    class_name: 'KubernetesToken',
    dependent: :destroy

  has_many :kubernetes_namespaces, dependent: :destroy

  has_many :docker_repos, dependent: :destroy

end
