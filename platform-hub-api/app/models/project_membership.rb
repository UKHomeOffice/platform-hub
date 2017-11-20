class ProjectMembership < ApplicationRecord

  self.primary_keys = :project_id, :user_id

  after_destroy :handle_destroy

  enum role: {
    admin: 'admin'
  }

  belongs_to :project
  validates :project_id, presence: true

  belongs_to :user
  validates :user_id, presence: true

  private

  def handle_destroy
    identity = self.user.kubernetes_identity
    if identity
      identity.tokens.by_project(self.project).each(&:destroy)
    end
  end

end
