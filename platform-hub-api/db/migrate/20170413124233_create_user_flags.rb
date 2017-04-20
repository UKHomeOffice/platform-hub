class CreateUserFlags < ActiveRecord::Migration[5.0]
  def change
    create_table :user_flags, id: :uuid do |t|
      t.boolean :completed_hub_onboarding, default: false

      t.timestamps
    end
  end
end
