class AddAliasesToKubernetesClusters < ActiveRecord::Migration[5.0]
  def change
    add_column :kubernetes_clusters, :aliases, :string, array: true, default: []
    add_index :kubernetes_clusters, :aliases, using: 'gin'
  end
end
