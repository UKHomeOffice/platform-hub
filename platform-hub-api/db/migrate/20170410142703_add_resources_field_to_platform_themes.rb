class AddResourcesFieldToPlatformThemes < ActiveRecord::Migration[5.0]
  def change
    add_column :platform_themes, :resources, :json
  end
end
