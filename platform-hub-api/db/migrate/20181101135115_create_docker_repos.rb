class CreateDockerRepos < ActiveRecord::Migration[5.0]
  def change
    create_table :docker_repos, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.belongs_to :service, type: :uuid, null: false, index: true
      t.string :status, null: false
      t.string :url

      t.timestamps

      t.index :name, unique: true
    end
  end
end
