class MeController < ApiJsonController

  def show
    render json: current_user, serializer: MeSerializer
  end

end
