class AddKubernetesGroupSearchIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :kubernetes_groups,
      "name gin_trgm_ops",
      name: 'kg_search_name_idx',
      using: :gin,
      order: { name: :gin_trgm_ops }

    add_index :kubernetes_groups,
      "description gin_trgm_ops",
      name: 'kg_search_description_idx',
      using: :gin,
      order: { name: :gin_trgm_ops }
  end
end
