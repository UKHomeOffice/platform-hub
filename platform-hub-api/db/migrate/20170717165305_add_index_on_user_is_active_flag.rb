class AddIndexOnUserIsActiveFlag < ActiveRecord::Migration[5.0]
  def change
    add_index :users, :is_active
  end
end
