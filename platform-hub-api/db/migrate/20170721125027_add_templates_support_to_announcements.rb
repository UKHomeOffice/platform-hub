class AddTemplatesSupportToAnnouncements < ActiveRecord::Migration[5.0]
  def change
    change_column_null :announcements, :title, true
    change_column_null :announcements, :text, true

    add_reference :announcements, :original_template, type: :uuid, index: true, null: true
    add_column :announcements, :template_definitions, :json, null: true
    add_column :announcements, :template_data, :json, null: true
  end
end
