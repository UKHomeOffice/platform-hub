class DockerRepo < ApplicationRecord

  NAME_REGEX = /\A[a-z]+[a-z0-9\-_\/]*\z/

  ACCESS_STATUS = {
    pending: 'pending',
    active: 'active',
    removing: 'removing',
    failed: 'failed',
  }.freeze

  include Audited
  include ValidateHashes

  audited descriptor_field: :name, associated_field: :service

  attr_readonly :name, :service_id, :provider

  before_validation :build_repo_name

  belongs_to :service, -> { readonly }

  scope :by_services, ->(ids) { where(service_id: ids) }

  enum status: {
    pending: 'pending',
    active: 'active',
    deleting: 'deleting',
    failed: 'failed',
  }

  enum provider: {
    ECR: 'ECR'
  }

  validates :name,
    presence: true,
    uniqueness: true,
    format: {
      with: NAME_REGEX,
      message: "must start with a letter and can only contain lowercase letters, numbers, hyphens, underscores, and forward slashes"
    }

  validates :service_id, presence: true

  validate_hashes(
    access: {
      schema: {
        'robots' => [[
          {
            'username' => /\A[a-z]+[a-z0-9\-_]*\z/i,
            'status' => DockerRepo::ACCESS_STATUS.values.to_set,
          }
        ]],
        'users' => [[
          {
            'username' => String,
            'writable' => TrueClass,
            'status' => DockerRepo::ACCESS_STATUS.values.to_set,
          }
        ]],
      },
      unique_checks: [
        { array_path: 'robots', obj_key: 'username' },
        { array_path: 'users', obj_key: 'username' },
      ]
    }
  )

  attr_default :status, :pending
  attr_default :access, -> { { 'robots' => [], 'users' => [] } }

  private

  def readonly?
    if persisted?
      read_only_attrs = self.class.readonly_attributes.to_a
      if read_only_attrs.any? {|f| send(:"#{f}_changed?")}
        raise ActiveRecord::ReadOnlyRecord, "#{read_only_attrs.join(', ')} can't be modified"
      end
    end
  end

  def build_repo_name
    return if persisted? || self.name.blank? || self.service.blank?
    self.name = "#{self.service.project.slug}/#{self.name}"
  end

end
