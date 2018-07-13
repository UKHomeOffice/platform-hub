module AllocationTestModels

  RSpec.shared_context 'allocation test models' do

    with_model :AllocatableModel do
      table id: :uuid do |t|
        t.timestamps
      end

      model do
        include Allocatable
        allocatable
      end
    end

    with_model :AllocationReceivableModel do
      table id: :uuid do |t|
        t.timestamps
      end

      model do
        include AllocationReceivable
        allocation_receivable
      end
    end

  end

end
