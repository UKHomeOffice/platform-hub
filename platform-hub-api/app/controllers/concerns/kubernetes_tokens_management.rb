module KubernetesTokensManagement
  extend ActiveSupport::Concern


  def create_kubernetes_token kind, params
    common_params = common_token_create_params(params)
    data = {
      token: SecureRandom.uuid,
      uid: SecureRandom.uuid,
      cluster: KubernetesCluster.friendly.find(common_params[:cluster_name]),
      groups: common_params[:groups],
      expire_token_at: nil
    }

    if common_params[:expire_token_at]!=nil
      data[:expire_token_at] = Time.now + (common_params[:expire_token_at])
    end

    token =
      case kind
      when 'user'
        user_params = user_token_create_params(params)
        project = Project.friendly.find(user_params[:project_id])
        identity = find_or_create_kubernetes_identity(user_params[:user_id])
        identity.tokens.new(
          data.merge(
            name: identity.user.email,
            project: project
          )
        )
      when 'robot'
        robot_params = robot_token_create_params(params)
        service = Service.find(robot_params[:service_id])
        service.kubernetes_robot_tokens.new(
          data.merge(
            name: robot_params[:name],
            description: robot_params[:description]
          )
        )
      else
        bad_request_error('Invalid `kind` specified') and return
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

  def update_kubernetes_token kind, token, params
    data =
      case kind
      when 'user'
        user_params = user_token_update_params(params)
        {
          groups: user_params[:groups]
        }
      when 'robot'
        robot_params = robot_token_update_params(params)
        {
          description: robot_params[:description],
          groups: robot_params[:groups]
        }
      else
        bad_request_error('Invalid `kind` specified') and return
      end

    if token.update(data)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: token,
        data: {
          cluster: token.cluster.name
        }
      )

      render json: token
    else
      render_model_errors token.errors
    end
  end

  def destroy_kubernetes_token token
    token.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: token,
      data: {
        cluster: token.cluster.name,
        obfuscated_token: token.obfuscated_token
      },
      comment: "User '#{current_user.email}' deleted #{token.kind} token (cluster: #{token.cluster.name}, name: #{token.name})"
    )

    head :no_content
  end

  private

  def find_or_create_kubernetes_identity(user_id)
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

  def common_token_create_params(params)
    params.permit(
      :cluster_name,
      :groups,
      {:groups => []},
      :expire_token_at
    )
  end

  def user_token_create_params(params)
    params.permit(
      :project_id,
      :user_id,
      :expire_token_at
    )
  end

  def robot_token_create_params(params)
    params.permit(
      :service_id,
      :name,
      :description
    )
  end

  def user_token_update_params(params)
    params.permit(
      :groups,
      {:groups => []},
      :expire_token_at
    )
  end

  def robot_token_update_params(params)
    params.permit(
      :groups,
      {:groups => []},
      :description
    )
  end

end
