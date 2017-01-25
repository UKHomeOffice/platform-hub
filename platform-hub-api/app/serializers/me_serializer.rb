class MeSerializer < ActiveModel::Serializer
  attributes :id, :name, :email

  has_many :identities
end
