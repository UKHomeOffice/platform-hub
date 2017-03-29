class AppSettingsController < ApiJsonController

  before_action :load_app_settings_hash_record

  skip_before_action :require_authentication, only: :show

  skip_authorization_check only: [ :show ]

  # GET /app_settings
  def show
    render json: @app_settings.data
  end

  # PATCH/PUT /app_settings
  def update
    authorize! :update, :app_settings

    if @app_settings.update(data: params[:app_setting])
      AuditService.log(
        context: audit_context,
        action: 'update_app_settings'
      )

      render json: @app_settings.data
    else
      render_model_errors @app_settings.errors
    end
  end

  private

  def load_app_settings_hash_record
    @app_settings = HashRecord.find_or_create_by!(id: 'app_settings', scope: 'webapp') do |r|
      r.data = {}
    end
  end

end
