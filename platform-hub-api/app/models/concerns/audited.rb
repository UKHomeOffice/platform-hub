module Audited
  extend ActiveSupport::Concern

  class_methods do

    def audited descriptor_field: nil, associated_field: nil
      has_many :audits, as: :auditable

      if descriptor_field
        define_method :audited_descriptor do
          self.send(descriptor_field)
        end
      end

      if associated_field
        define_method :audited_associated do
          self.send(associated_field)
        end
      end
    end

    def has_associated_audits
      has_many :associated_audits, as: :associated, class_name: 'Audit'
    end

  end

end
