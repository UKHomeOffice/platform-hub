class AddUserScopeToSupportRequestTemplate < ActiveRecord::Migration[5.0]
  def change
    add_column :support_request_templates, :user_scope, :string
  end
end
