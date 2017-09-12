class KubernetesTokenBase
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Associations
  include ActiveModel::Validations

  attr_accessor :cluster, :token, :uid, :groups

  validates_presence_of :cluster, :token, :uid
  validates_inclusion_of :cluster, in: proc {
    Kubernetes::ClusterService.list.map {|c| c['id']}
  }
  validate :token_must_not_be_blank

  def initialize(attributes)
    super(attributes)
  end

  def self.from_data(attributes)
    raise NotImplementedError
  end

  def [](attr)
    self.send(attr)
  end

  def []=(attr, value)
    self.send("#{attr}=", value)
  end

  def decrypted_token
    ENCRYPTOR.decrypt(self.token)
  end

  def token=(val)
    @token = ENCRYPTOR.encrypt(val)
  end

  protected

  def token_must_not_be_blank
    if decrypted_token.blank?
      errors.add(:token, "can't be nil or empty string")
    end
  end

end
