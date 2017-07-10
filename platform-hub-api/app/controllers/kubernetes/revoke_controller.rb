class Kubernetes::RevokeController < ApiJsonController

  # POST /kubernetes/revoke
  def revoke
    authorize! :manage, :identity
    
    begin
      summary = Kubernetes::TokenRevokeService.remove(params[:token])
    rescue Kubernetes::TokenRevokeService::Errors::TokenNotFound => e
      log_error e
      render_error "Kubernetes token not found.",
                    :unprocessable_entity and return
    rescue => e
      log_error e
      render_error "Kubernetes token revoke failed - #{e.message}",
                    :unprocessable_entity and return
    end

    summary.each do |cluster, msg|
      AuditService.log(
        context: audit_context,
        action: 'revoke_kubernetes_token',
        data: { cluster: cluster, token: params[:token] },
        comment: msg
      )
    end

    head :no_content
  end

  private

  def log_error(e)
    Rails.logger.error "Kubernetes token revoke failed - exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("\n")}"
  end

end
