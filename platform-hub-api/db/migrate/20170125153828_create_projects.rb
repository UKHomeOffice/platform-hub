class CreateProjects < ActiveRecord::Migration[5.0]
  def change
    create_table :projects, id: :uuid do |t|
      t.string :shortname, null: false
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
    add_index :projects, :shortname, unique: true
    add_index :projects, :slug, unique: true

    create_join_table :projects, :users, table_name: :project_memberships, column_options: { type: :uuid } do |t|
      t.index :user_id
      t.index :project_id
      t.index [:project_id, :user_id], unique: true
    end
  end
end
