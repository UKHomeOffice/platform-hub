class KubernetesToken < KubernetesTokenBase
  attr_accessor :identity_id, :expire_privileged_at

  validates_presence_of :identity_id

  belongs_to :identity

  def self.from_data(attributes)
    attributes = attributes.with_indifferent_access
    params = attributes
      .extract!(:identity_id, :cluster, :uid, :groups, :expire_privileged_at)
      .merge!(token: ENCRYPTOR.decrypt(attributes[:token]))
      .with_indifferent_access

    new(params)
  end

end
