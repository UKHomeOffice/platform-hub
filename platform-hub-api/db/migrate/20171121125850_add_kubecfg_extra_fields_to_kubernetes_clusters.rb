class AddKubecfgExtraFieldsToKubernetesClusters < ActiveRecord::Migration[5.0]
  def change
    add_column :kubernetes_clusters, :api_url, :string, null: false
    add_column :kubernetes_clusters, :ca_cert_encoded, :string, null: false
  end
end
