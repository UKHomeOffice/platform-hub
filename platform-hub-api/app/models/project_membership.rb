class ProjectMembership < ApplicationRecord

  enum role: {
    manager: 'manager'
  }

  belongs_to :project
  validates :project_id, presence: true

  belongs_to :user
  validates :user_id, presence: true

end
