class KubernetesCluster < ApplicationRecord

  NAME_REGEX = /\A[a-zA-Z][\w-]*\z/

  include Audited
  include FriendlyId
  include Allocatable

  audited descriptor_field: :name

  friendly_id :name

  allocatable

  before_save :downcase_name
  after_destroy :handle_destroy

  validates :name,
    format: {
      with: NAME_REGEX,
      message: "should consist of letters, numbers, underscores and dashes"
    }

  validates :name, presence: true, uniqueness: true

  validates :description, :s3_region, :s3_bucket_name, :s3_object_key,
            :s3_access_key_id, :s3_secret_access_key, presence: true

  has_many :tokens,
    class_name: KubernetesToken,
    foreign_key: :cluster_id,
    dependent: :destroy

  def s3_access_key_id=(val)
    self['s3_access_key_id'] = ENCRYPTOR.encrypt(val)
  end

  def s3_secret_access_key=(val)
    self['s3_secret_access_key'] = ENCRYPTOR.encrypt(val)
  end

  def decrypted_s3_access_key_id
    ENCRYPTOR.decrypt(s3_access_key_id)
  end

  def decrypted_s3_secret_access_key
    ENCRYPTOR.decrypt(s3_secret_access_key)
  end

  def self.names
    all.pluck(:name).sort
  end

  protected

  def downcase_name
    self.name.downcase!
  end

  private

  def handle_destroy
    KubernetesGroup.update_all_cluster_removal self
  end

end
