class SupportRequestTemplatesController < ApiJsonController

  before_action :find_support_request_template, only: [ :show, :update, :destroy ]

  skip_authorization_check :only => [ :index, :show, :form_field_types, :git_hub_repos ]
  authorize_resource except: [ :index, :show, :form_field_types, :git_hub_repos ]

  # GET /support_request_templates
  def index
    @support_request_templates = SupportRequestTemplate.order(:title)

    render json: @support_request_templates
  end

  # GET /support_request_templates/1
  def show
    render json: @support_request_template
  end

  # POST /support_request_templates
  def create
    @support_request_template = SupportRequestTemplate.new(support_request_template_params)

    if @support_request_template.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: @support_request_template
      )

      HelpSearchService.instance.index_item @support_request_template

      render json: @support_request_template, status: :created
    else
      render_model_errors @support_request_template.errors
    end
  end

  # PATCH/PUT /support_request_templates/1
  def update
    if @support_request_template.update(support_request_template_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @support_request_template
      )

      HelpSearchService.instance.index_item @support_request_template

      render json: @support_request_template
    else
      render_model_errors @support_request_template.errors
    end
  end

  # DELETE /support_request_templates/1
  def destroy
    id = @support_request_template.id
    shortname = @support_request_template.shortname

    @support_request_template.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      comment: "User '#{current_user.email}' deleted support request template: '#{shortname}' (ID: #{id})"
    )

    HelpSearchService.instance.delete_item @support_request_template

    head :no_content
  end

  # GET /support_request_templates/form_field_types
  def form_field_types
    render json: SupportRequestTemplate.form_field_types
  end

  # GET /support_request_templates/git_hub_repos
  def git_hub_repos
    render json: SupportRequestTemplate.git_hub_repos
  end

  private

  def find_support_request_template
    @support_request_template = SupportRequestTemplate.friendly.find params[:id]
  end

  # Only allow a trusted parameter "white list" through.
  def support_request_template_params
    allowed_params = params.require(:support_request_template).permit(:shortname, :git_hub_repo, :title, :description, :user_scope)

    # Below is a workaround until Rails 5.1 lands and we can use the `foo: {}` syntax to permit the whole hash
    allowed_params[:form_spec] = params[:support_request_template][:form_spec]
    allowed_params[:git_hub_issue_spec] = params[:support_request_template][:git_hub_issue_spec]
    allowed_params.permit!
  end

end
