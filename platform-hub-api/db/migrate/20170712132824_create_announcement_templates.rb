class CreateAnnouncementTemplates < ActiveRecord::Migration[5.0]
  def change
    create_table :announcement_templates, id: :uuid do |t|
      t.string :shortname, null: false
      t.string :slug, null: false
      t.text :description, null: false
      t.json :spec, null: false

      t.timestamps

      t.index :shortname, unique: true
      t.index :slug, unique: true
    end
  end
end
