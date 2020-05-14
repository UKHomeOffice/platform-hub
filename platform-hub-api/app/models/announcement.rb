class Announcement < ApplicationRecord

  include Audited

  audited descriptor_field: :title
  has_associated_audits

  acts_as_readable :on => :publish_at

  belongs_to :original_template, optional: true,
    class_name: 'AnnouncementTemplate'

  enum level: {
    info: 'info',
    warning: 'warning',
    critical: 'critical'
  }

  enum status: {
    awaiting_delivery: 'awaiting_delivery',
    awaiting_resend: 'awaiting_resend',
    delivery_not_required: 'delivery_not_required',
    delivering: 'delivering',
    delivered: 'delivered',
    delivery_failed: 'delivery_failed'
  }

  before_validation :set_template_definitions

  validates :title,
    presence: true,
    if: -> (a) { a.text.present? }

  validates :text,
    presence: true,
    if: -> (a) { a.title.present? }

  validates :original_template_id,
    presence: true,
    if: -> (a) { a.template_data.present? }

  validates :template_definitions,
    presence: true,
    if: -> (a) { a.original_template_id.present? || a.template_data.present? }

  validates :template_data,
    presence: true,
    if: -> (a) { a.original_template_id.present? || a.template_definitions.present? }

  validates :is_global,
    inclusion: { in: [ true, false ] }

  validates :is_sticky,
    inclusion: { in: [ true, false ] }

  validates :deliver_to,
    exclusion: {
      in: [ nil ],
      message: '%{value} should not be nil'
    }

  validates :publish_at,
    presence: true

  validates :status,
    presence: true

  validate :should_have_template_or_content

  attr_default :level, :info
  attr_default :is_global, false
  attr_default :is_sticky, false
  attr_default :deliver_to, -> { Hash.new }
  attr_default :status, :awaiting_delivery

  before_save do
    # Ignore if it's new or only the `status` field has changed (which is allowed)
    unless self.new_record? || self.changed == ['status']
      is_published = self.publish_at_was <= DateTime.now.utc
      is_not_awaiting_delivery = self.status_was != 'awaiting_delivery'

      self.readonly! if (
        is_published ||
        is_not_awaiting_delivery
      )
    end
  end

  scope :global, -> { where(is_global: true) }
  scope :published, -> { where('publish_at <= ?', DateTime.now.utc).order(publish_at: :desc) }
  scope :awaiting_delivery_or_resend, -> { where(status: [ :awaiting_delivery, :awaiting_resend ]) }

  def mark_sticky!
    self.update_column :is_sticky, true
  end

  def unmark_sticky!
    self.update_column :is_sticky, false
  end

  def has_delivery_targets?
    d = self.deliver_to
    return d.present? && !d.empty? && (
      (d['hub_users'].present? && !d['hub_users'].empty?) ||
      (d['contact_lists'].present? && !d['contact_lists'].empty?) ||
      (d['slack_channels'].present? && !d['slack_channels'].empty?)
    )
  end

  def published?
    self.publish_at <= DateTime.now.utc
  end

  def mark_for_resend!
    if self.published?
      self.status = :awaiting_resend
      self.save!
      true
    else
      false
    end
  end

  private

  def should_have_template_or_content

    # At this point we assume that some presence checks have been made (see above)

    template_fields = [ self.original_template_id, self.template_definitions, self.template_data ]
    content_fields = [ self.title, self.text ]

    if template_fields.any?(&:present?) && content_fields.any?(&:present?)
      errors[:base] << 'either a template can be specified or content directly, not both'
    end

    if template_fields.all?(&:blank?) && content_fields.all?(&:blank?)
      errors[:base] << 'either specify a template or content directly - currently neither is specified'
    end

  end

  def set_template_definitions
    if self.original_template.present? && (
      self.new_record? ||
      !self.published?
    )
      self.template_definitions = self.original_template.spec['templates']
    end
  end

end
