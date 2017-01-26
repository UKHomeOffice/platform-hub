class RootController < ApiJsonController

  skip_authorization_check :only => [ :index ]

  def index
    head :no_content
  end

end
