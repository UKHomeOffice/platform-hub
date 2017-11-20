module AllocationReceivable
  extend ActiveSupport::Concern

  class_methods do

    def allocation_receivable
      has_many :allocations,
        as: :allocation_receivable,
        dependent: :destroy
    end

  end

end
