class Announcement < ApplicationRecord

  include Audited

  audited descriptor_field: :title
  has_associated_audits

  enum level: {
    info: 'info',
    warning: 'warning',
    critical: 'critical'
  }

  enum status: {
    awaiting_delivery: 'awaiting_delivery',
    delivering: 'delivering',
    delivered: 'delivered'
  }

  validates :title,
    presence: true

  validates :text,
    presence: true

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

  def mark_sticky!
    self.update_column :is_sticky, true
  end

  def unmark_sticky!
    self.update_column :is_sticky, false
  end

end
