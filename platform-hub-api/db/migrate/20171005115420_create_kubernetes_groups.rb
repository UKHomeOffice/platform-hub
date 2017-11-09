class CreateKubernetesGroups < ActiveRecord::Migration[5.0]
  def change

    create_table :kubernetes_groups, id: :uuid do |t|
      t.string :name, null: false
      t.string :kind, null: false
      t.string :target, null: false
      t.text :description, null: false
      t.boolean :is_privileged, default: false
      t.string :restricted_to_clusters, array: true

      t.index :name, unique: true
      t.index :kind
      t.index :target
      t.index :is_privileged
      t.index :restricted_to_clusters, using: 'gin'

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        migrate_existing_data
      end
    end

  end

  def migrate_existing_data
    puts 'Migrating existing Kubernetes groups HashRecord entries to the new kubernetes_groups table'
    HashRecord.transaction do
      groups = HashRecord.kubernetes.find_by(id: 'groups')
      return if groups.nil?
      groups.data.each do |g|
        KubernetesGroup.create!(
          name: g['id'],
          kind: 'clusterwide',
          target: 'user',
          description: g['description'],
          is_privileged: g['privileged']
        )
      end
      groups.destroy!
    end
  end
end
