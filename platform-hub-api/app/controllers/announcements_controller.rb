class AnnouncementsController < ApiJsonController

  before_action :find_announcement, only: [ :show, :update, :destroy, :mark_sticky, :unmark_sticky ]

  skip_authorization_check :only => [ :global ]
  authorize_resource except: [ :global ]

  # GET /announcements
  def index
    @announcements = Announcement.order(created_at: :desc)

    render json: @announcements
  end

  # GET /announcement/global
  def global
    @announcements = GlobalAnnouncementsService.get_announcements

    render json: @announcements
  end

  # GET /announcements/1
  def show
    render json: @announcement
  end

  # POST /announcements
  def create
    @announcement = Announcement.new(announcement_params)

    # Handle template, if specified
    template_id = announcement_params[:original_template_id]
    if template_id
      template = AnnouncementTemplate.find template_id
      @announcement.original_template = template
    end

    if @announcement.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: @announcement
      )

      render json: @announcement, status: :created
    else
      render_model_errors @announcement.errors
    end
  end

  # PATCH/PUT /announcements/1
  def update
    if @announcement.update(announcement_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @announcement
      )

      render json: @announcement
    else
      render_model_errors @announcement.errors
    end
  end

  # DELETE /announcements/1
  def destroy
    id = @announcement.id
    title = @announcement.title

    @announcement.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      comment: "User '#{current_user.email}' deleted announcement: '#{title}' (#{id})"
    )
  end

  # POST /announcements/:id/mark_sticky
  def mark_sticky
    @announcement.mark_sticky!

    AuditService.log(
      context: audit_context,
      action: 'mark_sticky',
      auditable: @announcement
    )

    head :no_content
  end

  # POST /announcements/:id/unmark_sticky
  def unmark_sticky
    @announcement.unmark_sticky!

    AuditService.log(
      context: audit_context,
      action: 'unmark_sticky',
      auditable: @announcement
    )

    head :no_content
  end

  private

  def find_announcement
    @announcement = Announcement.find params[:id]
  end

  # Only allow a trusted parameter "white list" through
  def announcement_params
    allowed_params = params.require(:announcement).permit(:level, :original_template_id, :title, :text, :is_global, :is_sticky, :publish_at)

    # Below is a workaround until Rails 5.1 lands and we can use the `foo: [{}]` syntax to permit the whole array of hashes
    if params[:announcement][:deliver_to]
      allowed_params[:deliver_to] = params[:announcement][:deliver_to]
    end
    if params[:announcement][:template_data]
      allowed_params[:template_data] = params[:announcement][:template_data]
    end
    allowed_params.permit!
  end
end
