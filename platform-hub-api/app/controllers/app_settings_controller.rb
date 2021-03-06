class AppSettingsController < ApiJsonController

  PUBLIC_FIELDS = [
    'platformName',
    'platform_overview'
  ]

  skip_before_action :require_authentication, only: :show

  before_action :load_app_settings_hash_record

  skip_authorization_check only: :show

  # GET /app_settings
  def show
    if authenticated?
      render json: @app_settings.data
    else
      render json: @app_settings.data.select { |k,_| PUBLIC_FIELDS.include? k }
    end
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
