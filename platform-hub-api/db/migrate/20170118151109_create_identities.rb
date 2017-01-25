class CreateIdentities < ActiveRecord::Migration[5.0]
  def change
    create_table :identities, id: :uuid do |t|
      t.belongs_to :user, null: false, type: :uuid
      t.string :provider, null: false
      t.string :external_id, null: false
      t.string :external_username
      t.string :external_name
      t.string :external_email
      t.json :data

      t.timestamps
    end
  end
end
