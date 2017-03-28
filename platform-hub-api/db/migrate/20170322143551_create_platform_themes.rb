class CreatePlatformThemes < ActiveRecord::Migration[5.0]
  def change
    create_table :platform_themes, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description, null: false
      t.string :image_url, null: false
      t.string :colour, null: false

      t.timestamps

      t.index :title, unique: true
      t.index :slug, unique: true
    end
  end
end
