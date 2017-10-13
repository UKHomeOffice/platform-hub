module Allocatable
  extend ActiveSupport::Concern

  class_methods do

    def allocatable
      has_many :allocations, as: :allocatable
    end

  end

end
