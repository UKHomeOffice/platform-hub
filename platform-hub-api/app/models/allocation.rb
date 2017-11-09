class Allocation < ApplicationRecord

  include Audited

  audited associated_field: :allocation_receivable

  belongs_to :allocatable, polymorphic: true
  validates :allocatable_type, presence: true
  validates :allocatable_id, presence: true

  belongs_to :allocation_receivable, polymorphic: true
  validates :allocation_receivable_type, presence: true
  validates :allocation_receivable_id, presence: true

  validate :ensure_uniqueness

  scope :by_allocatable, -> (a) { where(allocatable: a) }
  scope :by_allocation_receivable, -> (ar) { where(allocation_receivable: ar) }

  private

  def ensure_uniqueness
    if Allocation.where(
      allocatable: self.allocatable,
      allocation_receivable: self.allocation_receivable
    ).exists?
      self.errors[:base] << 'Allocation already exists'
    end
  end

end
