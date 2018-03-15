class AddCostsBucketToClusters < ActiveRecord::Migration[5.0]
  def change
    add_column :kubernetes_clusters, :costs_bucket, :string
  end
end
