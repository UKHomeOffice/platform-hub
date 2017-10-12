class Kubernetes::TokensController < ApiJsonController

  before_action :find_token, only: [ :show, :update, :destroy, :escalate, :deescalate ]

  authorize_resource class: KubernetesToken

  # GET /kubernetes/tokens
  def index
    tokens = case params.require(:kind)
      when 'user'
        user = User.find params.require(:user_id)
        user.kubernetes_identity.tokens
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
    data = {
      token: SecureRandom.uuid,
      uid: SecureRandom.uuid,
      cluster: find_cluster(token_params[:cluster_name]),
      groups: token_params[:groups]
    }

    identity = find_identity(token_params[:user_id])

    token = 
      case token_params[:kind]
      when 'robot'
        identity.user.robot_tokens.new(
          data.merge(
            name: token_params[:name],
            description: token_params[:description]
          )
        )
      when 'user'
        identity.tokens.new(
          data.merge(
            name: identity.user.email
          )
        )
      end

    if token.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: token,
        data: {
          cluster: token.cluster.name
        }
      )
      render json: token, status: :created
    else
      render_model_errors token.errors
    end
  end

  # PATCH/PUT /kubernetes/tokens/:id
  def update
    data = 
      case token_params[:kind]
      when 'robot'
        {
          tokenable: User.find(token_params[:user_id]),
          description: token_params[:description],
          groups: token_params[:groups]
        }
      when 'user'
        {
          groups: token_params[:groups]
        }
      end

    if @token.update(data)
      AuditService.log(
        context: audit_context,
        action: 'update',
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

  # DELETE /kubernetes/tokens/:id
  def destroy
    @token.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @token,
      data: {
        cluster: @token.cluster.name
      },
      comment: "User '#{current_user.email}' deleted #{@token.kind} token (cluster: #{@token.cluster.name}, name: #{@token.name})"
    )

    head :no_content
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

  def find_identity(user_id)
    user = User.find user_id
    identity = user.kubernetes_identity

    if identity.nil?
      identity = user.identities.create!(
        provider: :kubernetes,
        external_id: user.email
      )
    end

    identity
  end

  def find_cluster(cluster_name)
    KubernetesCluster.friendly.find cluster_name
  end

  def find_token
    @token = KubernetesToken.find params[:id]
  end

  def token_params
    params.require(:token).permit(
      :kind,
      :user_id,
      :cluster_name,
      :groups,
      {:groups => []},
      # params below relevant for robot tokens only
      :name,
      :description
    )
  end

end
