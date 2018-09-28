class CreateQaEntries < ActiveRecord::Migration[5.0]
  def change
    create_table :qa_entries, id: :uuid do |t|
      t.string :question, null: false
      t.text :answer, null: false
      
      t.timestamps
    end
  end
end
