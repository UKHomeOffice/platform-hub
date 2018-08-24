class DocsSourceEntry < ApplicationRecord

  belongs_to :docs_source

  validates :content_id, presence: true

  validates :content_url, presence: true

end
