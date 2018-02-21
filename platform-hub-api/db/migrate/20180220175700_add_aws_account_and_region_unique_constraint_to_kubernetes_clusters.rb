class AddAwsAccountAndRegionUniqueConstraintToKubernetesClusters < ActiveRecord::Migration[5.0]
  def change
    add_index :kubernetes_clusters, [ :aws_account_id, :aws_region ], unique: true
  end
end
