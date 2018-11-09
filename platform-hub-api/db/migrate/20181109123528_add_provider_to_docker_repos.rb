class AddProviderToDockerRepos < ActiveRecord::Migration[5.0]
  def change
    add_column :docker_repos, :provider, :string, null: false
  end
end
