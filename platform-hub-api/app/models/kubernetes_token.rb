class KubernetesToken
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Associations

  attr_accessor :identity_id, :cluster, :token, :uid, :groups

  validates_presence_of :identity_id, :cluster, :token, :uid, :groups
  validates_inclusion_of :cluster, in: proc {
    HashRecord.kubernetes.find_by!(id: 'clusters').data.map {|c| c['id']}
  }

  belongs_to :identity

  def [](attr)
    self.send(attr)
  end

  def []=(attr, value)
    self.send("#{attr}=", value)
  end
end
