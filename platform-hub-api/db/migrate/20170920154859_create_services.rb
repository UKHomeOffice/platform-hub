class CreateServices < ActiveRecord::Migration[5.0]
  def change
    create_table :services, id: :uuid do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.belongs_to :project, type: :uuid, null: false

      t.timestamps
    end
  end
end
