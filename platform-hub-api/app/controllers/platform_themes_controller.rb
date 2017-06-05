class PlatformThemesController < ApiJsonController

  before_action :find_platform_theme, only: [ :show, :update, :destroy ]

  skip_authorization_check :only => [ :index, :show ]
  authorize_resource except: [ :index, :show ]

  # GET /platform_themes
  def index
    @platform_themes = PlatformTheme.order(:title)

    render json: @platform_themes
  end

  # GET /platform_themes/1
  def show
    render json: @platform_theme
  end

  # POST /platform_themes
  def create
    @platform_theme = PlatformTheme.new(platform_theme_params)

    if @platform_theme.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: @platform_theme
      )

      render json: @platform_theme, status: :created
    else
      render_model_errors @platform_theme.errors
    end
  end

  # PATCH/PUT /platform_themes/1
  def update
    if @platform_theme.update(platform_theme_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @platform_theme
      )

      render json: @platform_theme
    else
      render_model_errors @platform_theme.errors
    end
  end

  # DELETE /platform_themes/1
  def destroy
    id = @platform_theme.id
    title = @platform_theme.title

    @platform_theme.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      comment: "User '#{current_user.email}' deleted platform theme: '#{title}' (ID: #{id})"
    )
  end

  private

  def find_platform_theme
    @platform_theme = PlatformTheme.friendly.find params[:id]
  end

  # Only allow a trusted parameter "white list" through
  def platform_theme_params
    allowed_params = params.require(:platform_theme).permit(:title, :description, :image_url, :colour)

    # Below is a workaround until Rails 5.1 lands and we can use the `foo: [{}]` syntax to permit the whole array of hashes
    allowed_params[:resources] = params[:platform_theme][:resources]
    allowed_params.permit!
  end
end
