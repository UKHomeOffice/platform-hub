class ServiceSerializer < ActiveModel::Serializer
  attributes :id, :name, :description

  attribute :project do
    {
      id: object.project.friendly_id,
      shortname: object.project.shortname,
      name: object.project.name
    }
  end
end
