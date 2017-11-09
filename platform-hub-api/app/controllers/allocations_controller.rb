class AllocationsController < ApiJsonController

  before_action :find_allocation

  authorize_resource

  # DELETE /allocations/:id
  def destroy
    @allocation.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @allocation,
      comment: "User '#{current_user.email}' deleted allocation of #{@allocation.allocatable_type} '#{@allocation.allocatable_id}' to #{@allocation.allocation_receivable_type} '#{@allocation.allocation_receivable_id}'"
    )

    head :no_content
  end

  private

  def find_allocation
    @allocation = Allocation.find params[:id]
  end

end
