class KubernetesGroup < ApplicationRecord

  NAME_REGEX = /\A[a-zA-Z][\w:-]*\z/

  include Audited
  include FriendlyId

  audited descriptor_field: :name

  friendly_id :name

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

  enum target: {
    user: 'user',
    robot: 'robot'
  }

  scope :privileged, -> { where(is_privileged: true) }
  scope :not_privileged, -> { where.not(is_privileged: true) }

  def self.privileged_names
    privileged.pluck(:name)
  end

end
