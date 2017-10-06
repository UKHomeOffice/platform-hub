class Service < ApplicationRecord

  include Audited

  audited descriptor_field: :name, associated_field: :project

  validates :name,
    presence: true

  validates :description,
    presence: true

  belongs_to :project
  validates :project_id, presence: true

end
