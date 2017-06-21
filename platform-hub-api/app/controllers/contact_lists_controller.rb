class ContactListsController < ApiJsonController

  before_action :find_contact_list, only: [ :show, :destroy ]
  before_action :find_or_create_contact_list, only: [ :update ]

  authorize_resource

  # GET /contact_lists
  def index
    @contact_lists = ContactList.order(:id)

    render json: @contact_lists
  end

  # GET /contact_lists/foo
  def show
    render json: @contact_list
  end

  # PATCH/PUT /contact_lists/foo
  def update
    if @contact_list.update contact_list_params
      AuditService.log(
        context: audit_context,
        action: 'update_contact_list',
        comment: "User '#{current_user.email}' created/updated contact list: #{@contact_list.id}"
      )

      render json: @contact_list
    else
      render_model_errors @contact_list.errors
    end
  end

  # DELETE /contact_lists/foo
  def destroy
    id = @contact_list.id

    @contact_list.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy_contact_list',
      comment: "User '#{current_user.email}' deleted contact list: '#{id}')"
    )

    head :no_content
  end

  private

  def find_contact_list
    @contact_list = ContactList.find params[:id]
  end

  def find_or_create_contact_list
    @contact_list = ContactList.find_or_create_by!(id: params[:id]) do |cl|
      cl.email_addresses = []
    end
  end

  # Only allow a trusted parameter "white list" through
  def contact_list_params
    params.require(:contact_list).permit(email_addresses: [])
  end

end
