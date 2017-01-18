class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.datetime :last_seen_at

      t.timestamps
    end
  end
end
