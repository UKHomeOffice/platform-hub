class AddLastFetchMetdataToDocsSource < ActiveRecord::Migration[5.0]
  def change
    add_column :docs_sources, :last_successful_fetch_metadata, :json
  end
end
