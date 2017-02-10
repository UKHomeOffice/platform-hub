class ProjectMembership < ApplicationRecord

  include Audited

  enum role: {
    manager: 'manager'
  }

  belongs_to :project
  validates :project_id, presence: true

  belongs_to :user
  validates :user_id, presence: true

  private

end
