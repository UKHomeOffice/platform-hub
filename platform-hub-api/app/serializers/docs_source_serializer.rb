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
    :last_successful_fetch_metadata,
    :created_at,
    :updated_at
  )

  attribute :config do
    # Need to do this because `config` is a reserved word
    object.config
  end
end
