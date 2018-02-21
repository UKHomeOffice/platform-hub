class KubernetesCluster < ApplicationRecord

  NAME_REGEX = /\A[a-zA-Z][\w-]*\z/
  AWS_ACCOUNT_ID_REGEX = /\A[0-9]{12}\z/

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

  validates :aws_account_id,
    allow_nil: true,
    format: {
      with: AWS_ACCOUNT_ID_REGEX,
      message: "should be a number with 12 digits (ref: http://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html)"
    },
    uniqueness: {
      allow_nil: true,
      scope: :aws_region,
      message: "already has a cluster within the same region"
    }

  validates :aws_account_id,
    presence: {
      message: "can't be blank if AWS region is set"
    },
    if: ->(c) { c.aws_region.present? }

  validates :aws_region,
    allow_nil: true,
    uniqueness: {
      allow_nil: true,
      scope: :aws_account_id,
      message: "already has a cluster in the same AWS account"
    }

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
