class FeatureFlagsController < ApiJsonController

  skip_authorization_check only: :index

  # GET /feature_flags
  def index
    render json: FeatureFlagService.all
  end

  # PUT /feature_flags/:flag
  def update_flag
    authorize! :update, :feature_flags

    state = params.require(:feature_flag).require(:state)

    FeatureFlagService.create_or_update params[:flag], state

    index
  end

end
