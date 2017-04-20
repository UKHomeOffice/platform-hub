class MeController < ApiJsonController

  # This controller only ever acts on the currently authenticated user,
  # so we do not need to peform an authorization checks.
  skip_authorization_check

  def show
    render_me_resource
  end

  def delete_identity
    # We assume that the `service` param has been validated by the route constraints
    current_user.identity(params[:service]).destroy

    AuditService.log(
      context: audit_context,
      action: 'delete_identity',
      comment: "User '#{current_user.email}' removed their #{params[:service]} identity"
    )

    head :no_content
  end

  def complete_hub_onboarding
    current_user.is_managerial = params[:is_managerial]
    current_user.is_technical = params[:is_technical]

    current_user.update_flag :completed_hub_onboarding, true

    if current_user.save
      AuditService.log(
        context: audit_context,
        action: 'complete_hub_onboarding',
        comment: "User '#{current_user.email}' completed the hub onboarding"
      )

      render_me_resource
    else
      render_model_errors current_user.errors
    end
  end

  private

  def render_me_resource
    render json: current_user, serializer: MeSerializer
  end

end
