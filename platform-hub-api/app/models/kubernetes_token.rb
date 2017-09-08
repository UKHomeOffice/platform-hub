class KubernetesToken < KubernetesTokenBase
  attr_accessor :identity_id

  validates_presence_of :identity_id

  belongs_to :identity

  def self.from_data(attributes)
    attributes = attributes.with_indifferent_access
    params = attributes
      .extract!(:identity_id, :cluster, :uid, :groups)
      .merge!(token: ENCRYPTOR.decrypt(attributes[:token]))
      .with_indifferent_access

    new(params)
  end

end
