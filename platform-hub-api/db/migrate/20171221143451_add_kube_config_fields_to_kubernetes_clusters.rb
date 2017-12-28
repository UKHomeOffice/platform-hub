class AddKubeConfigFieldsToKubernetesClusters < ActiveRecord::Migration[5.0]
  def change
    add_column :kubernetes_clusters, :api_url, :string
    add_column :kubernetes_clusters, :ca_cert_encoded, :string
  end
end
