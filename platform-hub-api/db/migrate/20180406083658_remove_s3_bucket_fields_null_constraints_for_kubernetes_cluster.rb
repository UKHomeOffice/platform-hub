class RemoveS3BucketFieldsNullConstraintsForKubernetesCluster < ActiveRecord::Migration[5.0]
  def change
    change_column :kubernetes_clusters, :s3_region, :string, null: true
    change_column :kubernetes_clusters, :s3_bucket_name, :string, null: true
    change_column :kubernetes_clusters, :s3_access_key_id, :string, null: true
    change_column :kubernetes_clusters, :s3_secret_access_key, :string, null: true
    change_column :kubernetes_clusters, :s3_object_key, :string, null: true
  end
end
