class PrivilegedTokenExpirerJob < ApplicationJob
  queue_as :tokens_expirer

  IDENTITY_BATCH_SIZE = 100

  def self.is_already_queued
    Delayed::Job.where(queue: :tokens_expirer).count > 0
  end

  def perform
    return unless FeatureFlagService.is_enabled?(:kubernetes_tokens)

    privileged_group_names = KubernetesGroup.privileged_names

    Identity.kubernetes.find_each(batch_size: IDENTITY_BATCH_SIZE) do |i|
      should_update = false
      deescalated_token_group_clusters = []

      tokens = Kubernetes::TokenService.tokens_from_identity_data(i.data).each do |token|
        next if token.expire_privileged_at.nil? || DateTime.parse(token.expire_privileged_at).future?

        # Remove ALL privileged groups from user token groups and reset expiration timestamp
        token.groups = token.groups - privileged_group_names
        token.expire_privileged_at = nil

        deescalated_token_group_clusters << token.cluster
        should_update = true
      end

      if should_update
        i.with_lock do
          begin
            i.data[:tokens] = tokens
            i.save!

            deescalated_token_group_clusters.uniq.each do |cluster_id|
              AuditService.log(
                action: 'deescalate_kubernetes_token',
                auditable: i,
                data: { cluster: cluster_id },
                comment: "Privileged kubernetes token expired for `#{i.user.email}` in `#{cluster_id}` via background job."
              )
            end
          rescue => e
            Rails.logger.error "Privileged token expiration for user #{i.user.email} failed - exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("\n")}"
          end
        end
      end
    end
  end

end
