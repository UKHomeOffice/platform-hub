class ContactListsController < ApiJsonController

  before_action :find_contact_list

  authorize_resource

  # GET /contact_lists/:id
  def show
    render json: @contact_list
  end

  # PATCH/PUT /contact_lists/:id
  def update
    @contact_list.update contact_list_params

    AuditService.log(
      context: audit_context,
      action: 'update_contact_list',
      comment: "User '#{current_user.email}' updated contact list: #{params[:id]}"
    )

    render json: @contact_list
  end

  private

  def find_contact_list
    @contact_list = ContactList.find params[:id]
  end

  # Only allow a trusted parameter "white list" through
  def contact_list_params
    params.require(:contact_list).permit(email_addresses: [])
  end

end
