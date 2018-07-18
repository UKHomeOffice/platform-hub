class AddUserEmailSearchIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :users,
      "email gin_trgm_ops",
      name: 'users_search_email_idx',
      using: :gin,
      order: { name: :gin_trgm_ops }
  end
end
