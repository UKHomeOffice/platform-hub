class DockerRepo < ApplicationRecord

  NAME_REGEX = /\A[a-z]+[a-z0-9\-_\/]*\z/

  include Audited

  audited descriptor_field: :name, associated_field: :service

  attr_readonly :name, :service_id, :provider

  before_validation :build_repo_name

  belongs_to :service, -> { readonly }

  scope :by_services, ->(ids) { where(service_id: ids) }

  enum status: {
    pending: 'pending',
    ready: 'ready',
    deleting: 'deleting',
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

  attr_default :status, :pending

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
    self.name = "#{self.service.project.shortname.downcase}/#{self.name}"
  end

end
