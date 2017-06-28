class FeatureFlagsController < ApiJsonController

  skip_authorization_check

  # GET /feature_flags
  def index
    render json: FeatureFlagService.all
  end

end
