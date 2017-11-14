class ProjectMembership < ApplicationRecord

  self.primary_keys = :project_id, :user_id

  enum role: {
    admin: 'admin'
  }

  belongs_to :project
  validates :project_id, presence: true

  belongs_to :user
  validates :user_id, presence: true

end
