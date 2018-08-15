class DocsSource < ApplicationRecord

  include Audited

  audited descriptor_field: :name

  enum kind: {
    github_repo: 'github_repo',
    gitlab_repo: 'gitlab_repo'
  }

  enum last_fetch_status: {
    successful: 'successful',
    failed: 'failed'
  }

  validates :kind, presence: true

  validates :name, presence: true

  validates :is_fetching,
    inclusion: { in: [ true, false ] }

end
