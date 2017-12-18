class CreateCostsReports < ActiveRecord::Migration[5.0]
  def change
    create_table :costs_reports, id: :string do |t|
      t.integer :year, null: false
      t.string :month, null: false
      t.string :billing_file, null: false
      t.string :metrics_file, null: false
      t.text :notes
      t.json :config, null: false
      t.json :results, null: false

      t.timestamps
    end
  end
end
