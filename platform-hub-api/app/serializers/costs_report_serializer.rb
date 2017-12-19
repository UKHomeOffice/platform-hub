class CostsReportSerializer < BaseSerializer
  attributes(
    :id,
    :year,
    :month,
    :billing_file,
    :metrics_file,
    :notes,
    :created_at,
    :published_at
  )

  attribute :config do
    # Need to do this because `config` is a reserved word
    object.config
  end

  attribute :results
end
