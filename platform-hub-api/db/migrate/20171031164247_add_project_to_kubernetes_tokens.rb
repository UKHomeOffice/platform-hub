class AddProjectToKubernetesTokens < ActiveRecord::Migration[5.0]
  def change
    add_reference :kubernetes_tokens, :project, type: :uuid, index: true, null: false
  end
end
