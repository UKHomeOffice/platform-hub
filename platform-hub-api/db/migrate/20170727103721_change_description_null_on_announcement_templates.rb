class ChangeDescriptionNullOnAnnouncementTemplates < ActiveRecord::Migration[5.0]
  def change
    change_column_null :announcement_templates, :description, true
  end
end
