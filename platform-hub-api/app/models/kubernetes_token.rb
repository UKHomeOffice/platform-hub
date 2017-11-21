class KubernetesToken < ApplicationRecord
  TOKEN_LENGTH = 36
  UID_LENGTH = 36
  PRIVILEGED_GROUP_MAX_EXPIRATION_SECONDS = 21600 # max privilege period is 6h

  NAME_REGEX = /\A[a-zA-Z][\@\.\w-]*\z/

  include Audited
  audited descriptor_field: :name, associated_field: :tokenable

  attr_readonly :token, :name, :uid, :kind, :cluster_id, :project_id

  before_save :downcase_name

  belongs_to :tokenable, -> { readonly }, polymorphic: true
  belongs_to :project, -> { readonly }
  belongs_to :cluster, -> { readonly }, class_name: KubernetesCluster

  scope :privileged, -> { where.not(expire_privileged_at: nil) }
  scope :by_tokenable, ->(tokenable) { where(tokenable: tokenable) }
  scope :by_project, ->(project) { where(project: project) }
  scope :by_cluster, ->(c) { where(cluster: c) }
  scope :by_name, ->(n) { where(name: n.downcase) }

  enum kind: {
    user: 'user',
    robot: 'robot',
  }

  validates :uid, presence: true, length: { is: UID_LENGTH }, uniqueness: true
  validates :kind, :tokenable, :project, :cluster, presence: true
  validates :name,
    presence: true,
    format: {
      with: NAME_REGEX,
      message: "must start with letter and can only contain letters, numbers, underscores, dashes, dots and @"
    }
  validates :description, presence: true, if: :robot?

  before_validation :set_project, if: :robot?

  validate :tokenable_set
  validate :token_must_not_be_blank
  validate :token_must_be_of_expected_length
  validate :user_is_allowed_for_project
  validate :one_user_token_per_cluster_per_project
  validate :robot_name_unique_for_given_cluster
  validate :group_names_exist
  validate :allowed_clusters_only
  validate :allowed_groups_only

  def self.update_all_group_rename old_name, new_name
    sql = <<-SQL
      UPDATE kubernetes_tokens
      SET groups =
        array_replace(
          groups,
          #{connection.quote(old_name)},
          #{connection.quote(new_name)}
        )
    SQL
    connection.execute(sql)
  end

  def self.update_all_group_removal name
    sql = <<-SQL
      UPDATE kubernetes_tokens
      SET groups =
        array_remove(
          groups,
          #{connection.quote(name)}
        )
    SQL
    connection.execute(sql)
  end

  def token=(val)
    self['token'] = ENCRYPTOR.encrypt(val)
  end

  def groups=(groups)
    self['groups'] =
      if groups.is_a? String
        groups.split(',').map(&:strip).reject(&:blank?).uniq
      elsif groups.is_a? Array
        groups.uniq
      end
  end

  def decrypted_token
    ENCRYPTOR.decrypt(token)
  end

  def obfuscated_token
    val = decrypted_token
    val[0..30].gsub(/\w/, 'X') + val[31..35]
  end

  def privileged?
    expire_privileged_at.present?
  end

  def escalate(privileged_group_name, expires_in_secs = 600)
    group = KubernetesGroup.find_by!(name: privileged_group_name)

    unless is_group_valid?(group, allow_privileged_groups: true)
      errors[:base] << "group '#{privileged_group_name}' cannot be used to escalate privilege for this token"
      return false
    end

    # Update the db directly, bypassing validations.
    #
    # This is because the `allowed_groups_only` validation check won't allow
    # privileged groups to be set (to prevent project admins from explicitly
    # setting this when creating/editing tokens from the UI/API).
    update_columns(
      expire_privileged_at: [ expires_in_secs, PRIVILEGED_GROUP_MAX_EXPIRATION_SECONDS ].min.seconds.from_now,
      groups: groups << privileged_group_name
    )
  end

  def deescalate
    update_attributes(
      expire_privileged_at: nil,
      groups: groups - KubernetesGroup.privileged_names
    )
  end

  protected

  def set_project
    if tokenable.present? && tokenable.is_a?(Service)
      self.project = tokenable.project
    end
  end

  def tokenable_set
    if robot?
      errors.add(:tokenable_type, "must be `Service` for robot token") if tokenable_type != 'Service'
    elsif user?
      errors.add(:tokenable_type, "must be `Identity` for user token") if tokenable_type != 'Identity'
    end
    errors.add(:tokenable_id, "must be set for token") if tokenable_id.blank?
  end

  def token_must_not_be_blank
    if decrypted_token.blank?
      errors.add(:token, "can't be blank")
    end
  end

  def token_must_be_of_expected_length
    if decrypted_token.present? && decrypted_token.length != TOKEN_LENGTH
      errors.add(:token, "is the wrong length (should be #{TOKEN_LENGTH} characters)")
    end
  end

  def user_is_allowed_for_project
    return unless user? && project.present? && tokenable.present? && tokenable.is_a?(Identity)
    unless ProjectMembershipsService.is_user_a_member_of_project?(project.id, tokenable.user.id)
      errors.add(:user, "is not a member of the project")
    end
  end

  def one_user_token_per_cluster_per_project
    # For user token we only allow one per cluster
    return unless user? && cluster.present?
    if new_record? && KubernetesToken.user.by_tokenable(tokenable).by_cluster(cluster).by_project(project).exists?
      errors.add(:user, "already has a token for this project and cluster")
    end
  end

  def robot_name_unique_for_given_cluster
    # For robot token we allow multiple per cluster unique by name
    return unless robot?
    if new_record? && robot_token_for_cluster_and_name_exists?(cluster, name)
      errors.add(:name, "must be unique for each robot token within a cluster")
    end
  end

  def group_names_exist
    Array(self.groups).each do |g|
      unless KubernetesGroup.exists? name: g
        errors.add(:groups, "contain an invalid group - '#{g}' does not exist")
      end
    end
  end

  def allowed_clusters_only
    return unless project.present? && cluster.present?

    unless Allocation.exists?(
      allocatable: cluster,
      allocation_receivable: project
    )
      errors.add(:cluster_id, "is not allowed for this token")
    end
  end

  def allowed_groups_only
    return unless tokenable.present? && project.present? && cluster.present?

    if groups.present?
      groups.each do |name|
        g = KubernetesGroup.where(name: name).first

        # We assume at this point that the existence of the groups has already
        # been validated elsewhere. So just need to be defensive here.
        next if g.blank?

        unless is_group_valid?(g)
          errors.add(:groups, "contain an invalid group - '#{g.name}' is not allowed for this token")
        end
      end
    end
  end

  def downcase_name
    self.name.downcase!
  end

  def readonly?
    if persisted?
      read_only_attrs = self.class.readonly_attributes.to_a
      if read_only_attrs.any? {|f| send(:"#{f}_changed?")}
        raise ActiveRecord::ReadOnlyRecord, "#{read_only_attrs.join(', ')} can't be modified"
      end
    end
  end

  private

  def robot_token_for_cluster_and_name_exists?(cluster, name)
    return unless cluster.present? && name.present?
    KubernetesToken.robot.by_cluster(cluster).by_name(name).exists?
  end

  def is_group_valid? group, allow_privileged_groups: false
    privileged_check = allow_privileged_groups || !group.is_privileged

    group_target_allowed = if user?
      group.user?
    elsif robot?
      group.robot?
    else
      false
    end

    group_allowed_for_cluster = group.restricted_to_clusters.blank? ||
      group.restricted_to_clusters.include?(cluster.name)

    allocation_exists = Allocation.exists?(
      allocatable: group,
      allocation_receivable: project
    ) ||
      if user?
        Allocation.exists?(
          allocatable: group,
          allocation_receivable_type: Service.name,
          allocation_receivable_id: project.services.pluck(:id)
        )
      elsif robot?
        Allocation.exists?(
          allocatable: group,
          allocation_receivable: tokenable
        )
      else
        false
      end

    privileged_check &&
      group_target_allowed &&
      group_allowed_for_cluster &&
      allocation_exists
  end

end
