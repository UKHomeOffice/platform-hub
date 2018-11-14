class AddAccessToDockerRepos < ActiveRecord::Migration[5.0]
  def change
    add_column :docker_repos, :access, :jsonb
  end
end
