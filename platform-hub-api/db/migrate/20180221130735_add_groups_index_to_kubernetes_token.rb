class AddGroupsIndexToKubernetesToken < ActiveRecord::Migration[5.0]
  def change
    add_index :kubernetes_tokens, :groups, using: 'gin'
  end
end
