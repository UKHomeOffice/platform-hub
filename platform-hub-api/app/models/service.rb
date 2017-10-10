class Service < ApplicationRecord

  include Audited
  include AllocationReceivable

  audited descriptor_field: :name, associated_field: :project

  allocation_receivable

  validates :name,
    presence: true

  validates :description,
    presence: true

  belongs_to :project
  validates :project_id, presence: true

end
