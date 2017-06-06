class CreateAnnouncements < ActiveRecord::Migration[5.0]
  def change
    create_table :announcements, id: :uuid do |t|
      t.string :level, null: false
      t.string :title, null: false
      t.text :text, null: false
      t.boolean :is_global, null: false, default: false
      t.boolean :is_sticky, null: false, default: false
      t.json :deliver_to, null: false
      t.datetime :publish_at, null: false
      t.string :status, null: false

      t.timestamps
    end
  end
end
