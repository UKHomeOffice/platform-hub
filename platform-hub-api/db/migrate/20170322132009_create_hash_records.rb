class CreateHashRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :hash_records, id: :string do |t|
      t.string :scope, null: false
      t.json :data, null: false

      t.timestamps

      t.index :scope
    end
  end
end
