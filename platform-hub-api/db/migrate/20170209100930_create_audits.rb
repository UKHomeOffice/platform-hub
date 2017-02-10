class CreateAudits < ActiveRecord::Migration[5.0]
  def change
    create_table :audits do |t|
      t.belongs_to :auditable, polymorphic: true, type: :uuid
      t.string :auditable_descriptor
      t.belongs_to :associated, polymorphic: true, type: :uuid
      t.string :associated_descriptor
      t.belongs_to :user, type: :uuid
      t.string :user_name
      t.string :user_email
      t.string :action
      t.string :comment
      t.string :remote_ip
      t.string :request_uuid
      t.json :data

      t.datetime :created_at, null: false
    end

    add_index :audits, :user_name
    add_index :audits, :user_email
    add_index :audits, :remote_ip
    add_index :audits, :request_uuid
    add_index :audits, :created_at
  end
end
