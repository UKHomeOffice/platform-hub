class PlatformTheme < ApplicationRecord

  include FriendlyId
  include Audited

  audited descriptor_field: :title

  friendly_id :title, :use => :slugged

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  validates :title,
    presence: true,
    uniqueness: { case_sensitive: false }

  validates :title,
    presence: true

  validates :description,
    presence: true

  validates :image_url,
    presence: true

  validates :colour,
    presence: true

end
