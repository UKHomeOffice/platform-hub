class Kubernetes::RobotTokensController < ApiJsonController

  # GET /kubernetes/robot_tokens/:cluster
  def index
    authorize! :read, :kubernetes_robot_tokens
    tokens = Kubernetes::RobotTokenService.get_by_cluster params[:cluster]
    render json: tokens
  end


  # PUT/PATCH /kubernetes/robot_tokens/:cluster/:name
  def create_or_update
    authorize! :manage, :kubernetes_robot_tokens

    cluster = params[:cluster]
    name = params[:name]
    groups = params[:groups] || []
    description = params[:description]
    user_id = params[:user_id]

    Kubernetes::RobotTokenService.create_or_update cluster, name, groups, description, user_id

    AuditService.log(
      context: audit_context,
      action: 'update_kubernetes_robot_token',
      data: { cluster: cluster, name: name, user_id: user_id },
      comment: "Kubernetes `#{cluster}` robot token '#{name}' created or updated"
    )

    head :no_content
  end

  # DELETE /kubernetes/robot_tokens/:cluster/:name
  def destroy
    authorize! :manage, :kubernetes_robot_tokens

    cluster = params[:cluster]
    name = params[:name]

    Kubernetes::RobotTokenService.delete cluster, name

    AuditService.log(
      context: audit_context,
      action: 'destroy_kubernetes_robot_token',
      data: { cluster: cluster, name: name },
      comment: "Kubernetes `#{cluster}` robot token '#{name}' removed"
    )

    head :no_content
  end

end
