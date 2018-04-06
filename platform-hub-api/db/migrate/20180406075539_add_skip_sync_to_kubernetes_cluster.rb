class AddSkipSyncToKubernetesCluster < ActiveRecord::Migration[5.0]
  def change
    add_column :kubernetes_clusters, :skip_sync, :boolean, default: false
  end
end
