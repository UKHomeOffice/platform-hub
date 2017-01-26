class AddUserSearchIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :users,
      [ :name ],
      name: 'users_search_idx',
      using: :gin,
      order: { name: :gin_trgm_ops }
  end
end
