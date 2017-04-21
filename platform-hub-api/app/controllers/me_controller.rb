class MeController < ApiJsonController

  include GitHubOnboardingHelpers

  # This controller should only ever act on the currently authenticated user,
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

  def complete_services_onboarding
    # Currently only supports GitHub onboarding
    success = handle_onboard_github_request current_user, audit_context

    current_user.update_flag :completed_services_onboarding, true
    current_user.save  # Note: doesn't _really_ matter if this save fails – just means the flag won't get set

    if success
      AuditService.log(
        context: audit_context,
        action: 'complete_services_onboarding',
        comment: "User '#{current_user.email}' completed the services onboarding"
      )

      render_me_resource
    end
  end

  private

  def render_me_resource
    render json: current_user, serializer: MeSerializer
  end

end
