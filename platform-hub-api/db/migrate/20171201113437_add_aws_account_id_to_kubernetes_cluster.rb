class AddAwsAccountIdToKubernetesCluster < ActiveRecord::Migration[5.0]
  def change
    add_column :kubernetes_clusters, :aws_account_id, :integer, limit: 8
  end
end
