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
    user_identity = current_user.identity(params[:service])
    if user_identity.present?
      user_identity.destroy!

      AuditService.log(
        context: audit_context,
        action: 'delete_identity',
        comment: "User '#{current_user.email}' removed their #{params[:service]} identity"
      )

      head :no_content
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def agree_terms_of_service
    current_user.update_flag :agreed_to_terms_of_service, true

    if current_user.save
      AuditService.log(
        context: audit_context,
        action: 'agree_terms_of_service'
      )

      render_me_resource
    else
      render_model_errors current_user.errors
    end
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

  def global_announcements_mark_all_read
    GlobalAnnouncementsService.mark_all_read_for current_user

    render_me_resource
  end

  # GET /me/kubernetes_tokens
  def kubernetes_tokens
    kubernetes_identity = current_user.kubernetes_identity

    tokens = if kubernetes_identity.present?
      kubernetes_identity
        .tokens
        .includes(:project, :cluster)  # Eager load projects and clusters for performance
        .joins(:project, :cluster)
        .order('"projects"."name" ASC, "kubernetes_clusters"."name" ASC')  # Order by project and cluster names
    else
      []
    end

    render json: tokens
  end

  private

  def render_me_resource
    render json: current_user, serializer: MeSerializer
  end

end
