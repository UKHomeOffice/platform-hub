class CreateAllocations < ActiveRecord::Migration[5.0]
  def change
    create_table :allocations, id: :uuid do |t|
      t.references :allocatable,
        type: :uuid,
        polymorphic: true,
        null: false,
        index: {
          name: 'index_allocations_on_al_type_and_al_id'
        }

      t.references :allocation_receivable,
        type: :uuid,
        polymorphic: true,
        null: false,
        index: {
          name: 'index_allocations_on_al_rec_type_and_al_rec_id'
        }

      t.timestamps
    end
  end
end
