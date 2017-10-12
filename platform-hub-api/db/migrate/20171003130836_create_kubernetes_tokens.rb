class CreateKubernetesTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :kubernetes_tokens, id: :uuid do |t|
      t.references :tokenable, polymorphic: true, type: :uuid, null: false, index: true
      t.references :cluster, type: :uuid, null: false, index: true
      t.string :kind, null: false, index: true
      t.string :token, null: false
      t.string :name, null: false
      t.string :uid, null: false
      t.string :groups, array: true, default: []
      t.text :description
      t.datetime :expire_privileged_at

      t.timestamps
    end

    add_index :kubernetes_tokens, :token, unique: true
    add_index :kubernetes_tokens, :uid, unique: true
  end
end
