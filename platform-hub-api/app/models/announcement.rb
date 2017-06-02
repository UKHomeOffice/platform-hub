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
    waiting_delivery: 'waiting_delivery',
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

  validates :published_at,
    presence: true

  validates :status,
    presence: true

  attr_default :level, :info
  attr_default :is_global, false
  attr_default :is_sticky, false
  attr_default :deliver_to, -> { Hash.new }
  attr_default :status, :waiting_delivery

  after_find :update_protections
  after_create :update_protections
  after_update :update_protections

  scope :global, -> { where(is_global: true) }
  scope :published, -> { where('published_at <= ?', DateTime.now.utc).order(published_at: :desc) }

  private

  def update_protections
    if !self.waiting_delivery? || self.published_at <= DateTime.now.utc
      readonly!
    end
  end

end
