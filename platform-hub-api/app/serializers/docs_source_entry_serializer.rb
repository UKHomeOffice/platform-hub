class DocsSourceEntrySerializer < ActiveModel::Serializer
  attributes :id, :content_id, :content_url

  attribute :metadata
end
