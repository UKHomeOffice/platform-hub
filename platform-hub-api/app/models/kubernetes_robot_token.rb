class KubernetesRobotToken < KubernetesTokenBase
  attr_accessor :name

  validates_presence_of :name

  def self.from_data(cluster, attributes)
    attributes = attributes.with_indifferent_access
    params = attributes
      .extract!(:uid, :groups)
      .merge!(
        cluster: cluster,
        name: attributes[:user],
        token: ENCRYPTOR.decrypt(attributes[:token])
      )
      .with_indifferent_access

    new(params)
  end

end
