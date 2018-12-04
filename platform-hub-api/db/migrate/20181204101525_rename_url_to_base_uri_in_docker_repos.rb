class RenameUrlToBaseUriInDockerRepos < ActiveRecord::Migration[5.0]
  def change
    rename_column :docker_repos, :url, :base_uri
  end
end
