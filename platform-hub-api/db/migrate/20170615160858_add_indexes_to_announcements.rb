class AddIndexesToAnnouncements < ActiveRecord::Migration[5.0]
  def change
    add_index :announcements, :level
    add_index :announcements, :is_global
    add_index :announcements, :publish_at
    add_index :announcements, :status
  end
end
