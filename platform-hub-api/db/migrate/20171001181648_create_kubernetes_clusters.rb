class CreateKubernetesClusters < ActiveRecord::Migration[5.0]
  def up
    create_table :kubernetes_clusters, id: :uuid do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :s3_region, null: false
      t.string :s3_bucket_name, null: false
      t.string :s3_access_key_id, null: false
      t.string :s3_secret_access_key, null: false
      t.string :s3_object_key, null: false

      t.timestamps
    end

    add_index :kubernetes_clusters, :name, unique: true

    migrate_existing_data
  end

  def down
    drop_table :kubernetes_clusters
  end

  private

  def migrate_existing_data
    puts 'Migrating existing kubernetes cluster HashRecord entries to the new kubernetes_clusters table'
    HashRecord.transaction do
      clusters = HashRecord.kubernetes.find_by(id: 'clusters')
      clusters.data.each do |c|
        KubernetesCluster.create!(
          name: c['id'],
          description: c['description'],
          s3_region: c['config']['s3_bucket']['region'],
          s3_bucket_name: c['config']['s3_bucket']['bucket_name'],
          s3_access_key_id: ENCRYPTOR.decrypt(c['config']['s3_bucket']['access_key_id']),
          s3_secret_access_key: ENCRYPTOR.decrypt(c['config']['s3_bucket']['secret_access_key']),
          s3_object_key: c['config']['s3_bucket']['object_key']
        )
      end
      clusters.destroy!
    end
  end

end
