class AnnouncementsController < ApiJsonController

  before_action :find_announcement, only: [ :show, :update, :destroy ]

  skip_authorization_check :only => [ :global ]
  authorize_resource except: [ :global ]

  # GET /announcements
  def index
    @announcements = Announcement.order(created_at: :desc)

    render json: @announcements
  end

  # GET /announcement/global
  def global
    @announcements = Announcement.global.published

    render json: @announcements
  end

  # GET /announcements/1
  def show
    render json: @announcement
  end

  # POST /announcements
  def create
    @announcement = Announcement.new(announcement_params)

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

  private

  def find_announcement
    @announcement = Announcement.find params[:id]
  end

  # Only allow a trusted parameter "white list" through
  def announcement_params
    allowed_params = params.require(:announcement).permit(:level, :title, :text, :is_global, :is_sticky, :published_at)

    # Below is a workaround until Rails 5.1 lands and we can use the `foo: [{}]` syntax to permit the whole array of hashes
    if params[:announcement][:deliver_to]
      allowed_params[:deliver_to] = params[:announcement][:deliver_to]
    end
    allowed_params.permit!
  end
end
