class PrivilegedTokenExpirerJob < ApplicationJob
  queue_as :privileged_tokens_expirer

  BATCH_SIZE = 100

  def self.is_already_queued?
    Delayed::Job.where(queue: :privileged_tokens_expirer).count > 0
  end

  def perform
    return unless FeatureFlagService.is_enabled?(:kubernetes_tokens)

    KubernetesToken.privileged.find_each(batch_size: BATCH_SIZE).each do |t|
      next if t.expire_privileged_at.nil? || t.expire_privileged_at.future?

      if t.deescalate
        AuditService.log(
          action: 'deescalate',
          auditable: t
        )
      else
        Rails.logger.error "Privileged token expiration for token failed - ID: #{t.id}, name: #{t.name} - errors: #{t.errors.full_messages}"
      end
    end
  end

end
