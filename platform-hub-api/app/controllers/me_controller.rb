class MeController < ApiJsonController

  # This controller only ever acts on the currently authenticated user,
  # so we do not need to peform an authorization checks.
  skip_authorization_check

  def show
    render json: current_user, serializer: MeSerializer
  end

  def delete_identity
    # We assume that the `service` param has been validated by the route constraints
    current_user.identity(params[:service]).destroy
    head :no_content
  end

end
