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
  before_validation :process_aliases
  after_destroy :handle_destroy

  scope :by_alias, -> (value) {
    where("aliases @> ARRAY[?]::varchar[]", Array(value.downcase))
  }

  scope :by_name_or_alias, -> (value) {
    where(name: value.downcase).or(by_alias(value))
  }

  scope :syncable, -> { where(skip_sync: false) }

  validates :name,
    format: {
      with: NAME_REGEX,
      message: "should consist of letters, numbers, underscores and dashes"
    }

  validates :name, presence: true, uniqueness: true

  validates :description, :s3_region, :s3_bucket_name, :s3_object_key,
            :s3_access_key_id, :s3_secret_access_key,
            presence: true,
            unless: :skip_sync

  validates :aws_account_id,
    allow_nil: true,
    format: {
      with: AWS_ACCOUNT_ID_REGEX,
      message: "should be a number with 12 digits (ref: http://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html)"
    }

  validate :ensure_unique_aliases_incl_names

  has_many :tokens,
    class_name: 'KubernetesToken',
    foreign_key: :cluster_id,
    dependent: :destroy

  has_many :namespaces,
    class_name: 'KubernetesNamespace',
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

  private

  def downcase_name
    self.name.downcase!
  end

  def process_aliases
    return if self.aliases.blank?
    self.aliases = self.aliases.compact.map(&:downcase).uniq.sort
  end

  def ensure_unique_aliases_incl_names
    aliases_to_check =
      if new_record?
        # Check all as none of them should exist
        Array(self.aliases)
      else
        # Only need to worry about *new* aliases that are trying to be set here
        Array(self.aliases) - Array(self.aliases_was)
      end

    aliases_to_check.each do |a|
      if KubernetesCluster.by_name_or_alias(a).exists?
        errors.add(:aliases, 'contains a value that is already being used as the name, or an alias, of an existing cluster')
      end
    end
  end

  def handle_destroy
    KubernetesGroup.update_all_cluster_removal self
  end

end
