class Allocation < ApplicationRecord

  include Audited

  audited associated_field: :allocation_receivable

  belongs_to :allocatable, polymorphic: true
  validates :allocatable_type, presence: true
  validates :allocatable_id, presence: true

  belongs_to :allocation_receivable, polymorphic: true
  validates :allocation_receivable_type, presence: true
  validates :allocation_receivable_id, presence: true

end
