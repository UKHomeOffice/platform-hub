class CreateKubernetesNamespaces < ActiveRecord::Migration[5.0]
  def change
    create_table :kubernetes_namespaces, id: :uuid do |t|
      t.references :service, type: :uuid, null: false, index: true
      t.references :cluster, type: :uuid, null: false, index: true
      t.string :name, null: false
      t.text :description

      t.timestamps

      t.index [ :name, :cluster_id ], unique: true
    end
  end
end
