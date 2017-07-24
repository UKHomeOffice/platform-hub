class AnnouncementTemplatesController < ApiJsonController

  before_action :find_announcement_template, only: [ :show, :update, :destroy ]

  authorize_resource

  # GET /announcement_templates
  def index
    @announcement_templates = AnnouncementTemplate.order(:shortname)

    render json: @announcement_templates
  end

  # GET /announcement_templates/1
  def show
    render json: @announcement_template
  end

  # POST /announcement_templates
  def create
    @announcement_template = AnnouncementTemplate.new(announcement_template_params)

    if @announcement_template.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: @announcement_template
      )

      render json: @announcement_template, status: :created
    else
      render_model_errors @announcement_template.errors
    end
  end

  # PATCH/PUT /announcement_templates/1
  def update
    if @announcement_template.update(announcement_template_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @announcement_template
      )

      render json: @announcement_template
    else
      render_model_errors @announcement_template.errors
    end
  end

  # DELETE /announcement_templates/1
  def destroy
    id = @announcement_template.id
    shortname = @announcement_template.shortname

    @announcement_template.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      comment: "User '#{current_user.email}' deleted announcement template: '#{shortname}' (ID: #{id})"
    )

    head :no_content
  end

  # GET /announcement_templates/form_field_types
  def form_field_types
    render json: AnnouncementTemplate.form_field_types
  end

  # POST /announcement_templates/preview
  def preview
    templates, data = params.require([:templates, :data])
    results = AnnouncementFormatterService.format templates, data
    render json: results
  end

  private

  def find_announcement_template
    @announcement_template = AnnouncementTemplate.friendly.find params[:id]
  end

  # Only allow a trusted parameter "white list" through.
  def announcement_template_params
    allowed_params = params.require(:announcement_template).permit(:shortname, :description)

    # Below is a workaround until Rails 5.1 lands and we can use the `foo: {}` syntax to permit the whole hash
    if params[:announcement_template][:spec]
      allowed_params[:spec] = params[:announcement_template][:spec]
    end
    allowed_params.permit!
  end
end
