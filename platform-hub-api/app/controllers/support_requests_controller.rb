class SupportRequestsController < ApiJsonController

  include AgentsInitializer

  skip_authorization_check :only => [ :create ]  # Any authenticated user can create a support request

  # POST /support_requests
  def create
    template = SupportRequestTemplate.friendly.find params[:template_id]

    data = params[:data]
    if data.blank?
      render_error "Missing 'data' field", :unprocessable_entity
      return
    end

    formatted_result = SupportRequestFormatterService.format template, data, current_user

    repo_url = template.git_hub_repo
    title = formatted_result.title
    body = formatted_result.body

    begin
      url = git_hub_agent_service.create_issue repo_url, title, body
    rescue => e
      logger.error "Failed to call the GitHub API to create a support request issue. Exception type: #{e.class.name}. Message: #{e.message}"
      render_error 'Unknown error whilst submitting the support request to GitHub', :service_unavailable
      return
    end

    AuditService.log(
      context: audit_context,
      action: 'create_request_from',
      auditable: template,
      comment: "GitHub issue: #{url}"
    )

    render json: {
      url: url,
      title: title,
      body: body
    }
  end

end
