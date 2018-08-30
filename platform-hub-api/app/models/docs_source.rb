class DocsSource < ApplicationRecord

  include Audited

  audited descriptor_field: :name

  attr_readonly :kind

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

  private

  def readonly?
    if persisted?
      read_only_attrs = self.class.readonly_attributes.to_a
      if read_only_attrs.any? {|f| send(:"#{f}_changed?")}
        raise ActiveRecord::ReadOnlyRecord, "#{read_only_attrs.join(', ')} can't be modified"
      end
    end
  end

end
