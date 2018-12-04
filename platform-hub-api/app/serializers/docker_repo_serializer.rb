class DockerRepoSerializer < ActiveModel::Serializer
  attributes :id, :name, :base_uri, :description, :status, :provider

  belongs_to :service

  attribute :access

  attributes :created_at, :updated_at
end
