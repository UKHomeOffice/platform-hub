module Allocatable
  extend ActiveSupport::Concern

  class_methods do

    def allocatable
      has_many :allocations,
        as: :allocatable,
        dependent: :delete_all
    end

  end

end
