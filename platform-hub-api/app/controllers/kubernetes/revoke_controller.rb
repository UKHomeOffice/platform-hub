class Kubernetes::RevokeController < ApiJsonController

  before_action :find_token, only: [ :revoke ]

  authorize_resource class: KubernetesToken

  # POST /kubernetes/revoke
  def revoke
    @token.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @token,
      data: {
        cluster: @token.cluster.name
      },
      comment: "User '#{current_user.email}' revoked `#{@token.cluster.name}` token for `#{@token.user.email}`."
    )

    head :no_content
  end

  private

  def find_token
    @token = KubernetesToken.all.find {|t| t.decrypted_token == params[:token]}
    raise ActiveRecord::RecordNotFound if @token.nil?
  end

end
