class AddAwsRegionToKubernetesCluster < ActiveRecord::Migration[5.0]
  def change
    add_column :kubernetes_clusters, :aws_region, :string
  end
end
