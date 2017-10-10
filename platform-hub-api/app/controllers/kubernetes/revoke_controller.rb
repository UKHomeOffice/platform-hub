class Kubernetes::RevokeController < ApiJsonController

  before_action :find_token, only: [ :revoke ]

  authorize_resource class: KubernetesToken

  # POST /kubernetes/revoke
  def revoke
    @token.destroy

    AuditService.log(
      context: audit_context,
      action: 'revoke',
      comment: "User '#{current_user.email}' revoked #{@token.kind} token (cluster: #{@token.cluster.name}, name: #{@token.name})"
    )

    head :no_content
  end

  private

  def find_token
    @token = KubernetesToken.all.find {|t| t.decrypted_token == params[:token]}
    render_error 'Resource not found', :not_found if @token.nil?
  end

end
