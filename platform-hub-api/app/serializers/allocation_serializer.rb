class AllocationSerializer < BaseSerializer
  attribute :id

  belongs_to :allocatable, polymorphic: true
  belongs_to :allocation_receivable, polymorphic: true

  attribute :created_at
end
