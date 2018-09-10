class CreateDocsSourceEntries < ActiveRecord::Migration[5.0]
  def change
    create_table :docs_source_entries, id: :uuid do |t|
      t.references :docs_source, type: :uuid, null: false, index: true
      t.string :content_id, null: false
      t.string :content_url, null: false
      t.json :metadata

      t.timestamps
    end
  end
end
