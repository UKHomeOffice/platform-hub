class Kubernetes::ClaimController < ApiJsonController

  # This controller should only ever act on the currently authenticated user,
  # so we do not need to peform an authorization checks.
  skip_authorization_check

  # POST /kubernetes/claim
  def claim
    begin
      summary = Kubernetes::TokenClaimService.claim_token(current_user, params[:token])
    rescue Kubernetes::TokenClaimService::Errors::TokenNotFound => e
      log_error e
      render_error "Kubernetes token not found.",
                    :unprocessable_entity and return
    rescue Kubernetes::TokenClaimService::Errors::TokenAlreadyClaimed => e
      log_error e
      render_error "Kubernetes token already claimed.",
                    :unprocessable_entity and return
    rescue => e
      log_error e
      render_error "Kubernetes token claim failed. Try again later.",
                    :unprocessable_entity and return
    end

    summary.each do |cluster, msg|
      AuditService.log(
        context: audit_context,
        action: 'claim_kubernetes_token',
        data: { cluster: cluster, user_id: current_user.id, token: ENCRYPTOR.encrypt(params[:token]) },
        comment: msg
      )
    end

    head :no_content
  end

  private

  def log_error(e)
    Rails.logger.error "Kubernetes token claim failed - exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("\n")}"
  end

end
