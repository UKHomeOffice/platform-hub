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

  def initialize(attributes)
    super(attributes)
  end

  def self.from_data(attributes)
    params = attributes.extract!(:identity_id, :cluster, :uid, :groups)
        .merge!(token: ENCRYPTOR.decrypt(attributes[:token]))

    new(params)
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
