class QaEntry < ApplicationRecord

  include Audited

  audited descriptor_field: :question

  validates :question, presence: true

  validates :answer, presence: true

end
