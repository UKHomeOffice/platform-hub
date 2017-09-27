class KubernetesRobotToken < KubernetesTokenBase
  attr_accessor :name, :description, :user_id

  validates_presence_of :name

  belongs_to :user

  def self.from_data(cluster, attributes)
    attributes = attributes.with_indifferent_access
    params = attributes
      .extract!(:uid, :groups, :description, :user_id)
      .merge!(
        cluster: cluster,
        name: attributes[:user],
        token: ENCRYPTOR.decrypt(attributes[:token])
      )
      .with_indifferent_access

    new(params)
  end

end
