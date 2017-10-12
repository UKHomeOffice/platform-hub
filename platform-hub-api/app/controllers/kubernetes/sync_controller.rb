class Kubernetes::SyncController < ApiJsonController

  # POST /kubernetes/sync
  def sync
    authorize! :manage, KubernetesToken

    begin
      Kubernetes::TokenSyncService.sync_tokens(params[:cluster])
    rescue => e
      log_error e
      render_error "Kubernetes tokens sync to `#{params[:cluster]}` cluster failed - #{e.message}", 
                    :unprocessable_entity and return
    end

    AuditService.log(
      context: audit_context,
      action: 'sync_kubernetes_tokens',
      data: { cluster: params[:cluster] },
      comment: "Kubernetes tokens synced to `#{params[:cluster]}` cluster."
    )

    head :no_content
  end

  private

  def log_error(e)
    Rails.logger.error "Kubernetes tokens sync to `#{params[:cluster]}` cluster failed - exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("\n")}"
  end

end
