class KubernetesGroup < ApplicationRecord

  NAME_REGEX = /\A[a-zA-Z][\w:-]*\z/

  include Audited
  include FriendlyId
  include Allocatable

  audited descriptor_field: :name

  friendly_id :name

  allocatable

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

  scope :privileged, -> { where(is_privileged: true) }
  scope :not_privileged, -> { where.not(is_privileged: true) }

  def self.privileged_names
    privileged.pluck(:name)
  end

end
