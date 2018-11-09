class DockerRepoSerializer < ActiveModel::Serializer
  attributes :id, :name, :url, :description, :status, :provider

  belongs_to :service

  attributes :created_at, :updated_at
end
