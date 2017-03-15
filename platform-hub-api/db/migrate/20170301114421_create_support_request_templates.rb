class CreateSupportRequestTemplates < ActiveRecord::Migration[5.0]
  def change
    create_table :support_request_templates, id: :uuid do |t|
      t.string :shortname, null: false
      t.string :slug, null: false
      t.string :git_hub_repo, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.json :form_spec, null: false
      t.json :git_hub_issue_spec, null: false

      t.timestamps

      t.index :shortname, unique: true
      t.index :slug, unique: true
      t.index :git_hub_repo
    end
  end
end
