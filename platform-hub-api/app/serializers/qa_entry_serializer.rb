class QaEntrySerializer < ActiveModel::Serializer
  attributes :id, :question, :answer, :created_at, :updated_at
end
