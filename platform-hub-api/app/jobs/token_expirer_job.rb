class TokenExpirerJob < ApplicationJob
  queue_as :tokens_expirer

  BATCH_SIZE = 100

  def self.is_already_queued?
    Delayed::Job.where(queue: :tokens_expirer).count > 0
  end

  def perform
    return unless FeatureFlagService.is_enabled?(:kubernetes_tokens)

    KubernetesToken.timed.find_each(batch_size: BATCH_SIZE).each do |t|
      next if t.expire_token_at.nil? || t.expire_token_at.future?

      if t.destroy_expired_token
        AuditService.log(
          action: 'destroy_expired_token',
          auditable: t
        )
      else
        Rails.logger.error "token expiration for token failed - ID: #{t.id}, name: #{t.name} - errors: #{t.errors.full_messages}"
      end
    end
  end

end
