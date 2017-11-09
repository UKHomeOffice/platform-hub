class Audit < ApplicationRecord

  belongs_to :auditable, polymorphic: true
  belongs_to :associated, polymorphic: true
  belongs_to :user

  before_create :set_associated_if_needed
  before_create :set_descriptors_if_needed
  before_create :denormalise_user_fields
  after_create :output_log_message
  after_create { readonly! }
  after_find { readonly! }
  before_destroy { raise ActiveRecord::ReadOnlyRecord }

  scope :ascending, -> { reorder(version: :asc) }
  scope :descending, -> { reorder(version: :desc) }
  scope :by_action, -> (action) { where(action: action) }
  scope :by_auditable, -> (auditable_id, auditable_type) { where(auditable_id: auditable_id, auditable_type: auditable_type) }
  scope :by_auditable_type, -> (auditable_type) { where(auditable_type: auditable_type) }
  scope :by_associated, -> (associated_id, associated_type) { where(associated_id: associated_id, associated_type: associated_type) }

  def message
    m = []
    m << "[Audit] Action: #{self.action}"
    m << "By user: #{self.user.id} - #{self.user_name} - #{self.user_email}" if self.user
    m << "On thing: #{self.auditable_type} - #{self.auditable_id} - #{self.auditable_descriptor}" if self.auditable
    m << "Associated to: #{self.associated_type} - #{self.associated_id} - #{self.associated_descriptor}" if self.associated
    m << "Comment: #{self.comment}" if self.comment
    m << "Remote IP: #{self.remote_ip}" if self.remote_ip
    m << "Request UUID: #{self.request_uuid}" if self.request_uuid
    m.join(' | ')
  end

  private

  def set_associated_if_needed
    if self.associated.blank? &&
       self.auditable.present? &&
       self.auditable.respond_to?(:audited_associated)
      self.associated = self.auditable.audited_associated
    end
  end

  def set_descriptors_if_needed
    if self.auditable_descriptor.blank? &&
       self.auditable.present? &&
       self.auditable.respond_to?(:audited_descriptor)
      self.auditable_descriptor = self.auditable.audited_descriptor
    end

    if self.associated_descriptor.blank? &&
       self.associated.present? &&
       self.associated.respond_to?(:audited_descriptor)
      self.associated_descriptor = self.associated.audited_descriptor
    end
  end

  def denormalise_user_fields
    if self.user
      self.user_name = self.user.name
      self.user_email = self.user.email
    end
  end

  def output_log_message
    logger.info self.message
  end

end
