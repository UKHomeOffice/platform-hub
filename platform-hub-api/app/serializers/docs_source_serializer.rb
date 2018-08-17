class DocsSourceSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :kind,
    :name,
    :config,
    :is_fetching,
    :last_fetch_status,
    :last_fetch_started_at,
    :last_fetch_error,
    :last_successful_fetch_started_at,
    :created_at,
    :updated_at
  )
end
