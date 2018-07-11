module Allocatable
  extend ActiveSupport::Concern

  class_methods do

    def allocatable
      has_many :allocations,
        as: :allocatable,
        dependent: :destroy

      scope :unallocated, -> do
        left_outer_joins(:allocations)
          .where('allocations.allocatable_id IS NULL')
      end
    end

  end

end
