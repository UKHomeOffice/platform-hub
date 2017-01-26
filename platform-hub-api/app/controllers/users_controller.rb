class UsersController < ApiJsonController

  before_action :find_user, only: [ :show, :make_admin, :revoke_admin ]

  authorize_resource

  # GET /users
  def index
    @users = User.order(:name)

    render json: @users
  end

  # GET /users/:id
  def show
    render json: @user
  end

  # GET /users/:id/make_admin
  def make_admin
    @user.make_admin!
    head :no_content
  end

  # GET /users/search/:q
  def search
    render json: User.search(params[:q])
  end

  # GET /users/:id/revoke_admin
  def revoke_admin
    @user.revoke_admin!
    head :no_content
  end

  private

  def find_user
    @user = User.find params[:id]
  end

end
