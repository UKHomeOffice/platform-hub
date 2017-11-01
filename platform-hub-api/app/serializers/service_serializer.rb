class ServiceSerializer < ActiveModel::Serializer
  attributes :id, :name, :description

  belongs_to :project, serializer: ProjectEmbeddedSerializer
end
