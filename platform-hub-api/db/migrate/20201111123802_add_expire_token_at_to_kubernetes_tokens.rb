class AddExpireTokenAtToKubernetesTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :kubernetes_tokens, :expire_token_at, :timestamp
  end
end
