class Kubernetes::TokensController < ApiJsonController

  include KubernetesTokensManagement

  before_action :find_token, only: [ :show, :update, :destroy, :escalate, :deescalate ]

  authorize_resource class: KubernetesToken

  # GET /kubernetes/tokens
  def index
    tokens = case params.require(:kind)
      when 'user'
        user = User.find params.require(:user_id)
        user.kubernetes_identity ? user.kubernetes_identity.tokens : []
      when 'robot'
        cluster = KubernetesCluster.find_by! name: params.require(:cluster_name)
        KubernetesToken.robot.by_cluster(cluster)
      end

    render json: tokens
  end

  # GET /kubernetes/tokens/:id
  def show
    render json: @token
  end

  # POST /kubernetes/tokens
  def create
    token_params = params.require(:token)
    kind = token_params.require(:kind)
    create_kubernetes_token kind, token_params
  end

  # PATCH/PUT /kubernetes/tokens/:id
  def update
    token_params = params.require(:token)
    kind = token_params.require(:kind)
    update_kubernetes_token kind, @token, token_params
  end

  # DELETE /kubernetes/tokens/:id
  def destroy
    destroy_kubernetes_token @token
  end


  # PATCH /kubernetes/tokens/:id/escalate
  def escalate
    privileged_group, expires_in_secs = params.require([:privileged_group, :expires_in_secs])

    if @token.escalate(privileged_group, expires_in_secs)
      AuditService.log(
        context: audit_context,
        action: 'escalate',
        auditable: @token,
        data: {
          cluster: @token.cluster.name,
          privileged_group: privileged_group
        }
      )

      render json: @token
    else
      render_model_errors @token.errors
    end
  end

  # PATCH /kubernetes/tokens/:id/deescalate
  def deescalate
    if @token.deescalate
      AuditService.log(
        context: audit_context,
        action: 'deescalate',
        auditable: @token,
        data: {
          cluster: @token.cluster.name
        }
      )

      render json: @token
    else
      render_model_errors @token.errors
    end
  end

  private

  def find_token
    @token = KubernetesToken.find params[:id]
  end



end
