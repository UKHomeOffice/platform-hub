class CreateDocsSources < ActiveRecord::Migration[5.0]
  def change
    create_table :docs_sources, id: :uuid do |t|
      t.string :kind, null: false, index: true
      t.string :name, null: false
      t.json :config, null: false
      t.boolean :is_fetching, null: false, default: false
      t.string :last_fetch_status
      t.datetime :last_fetch_started_at
      t.string :last_fetch_error
      t.datetime :last_successful_fetch_started_at

      t.timestamps
    end
  end
end
