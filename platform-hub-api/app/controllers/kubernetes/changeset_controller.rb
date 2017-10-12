class Kubernetes::ChangesetController < ApiJsonController

  before_action :load_audits

  authorize_resource class: Audit

  # GET /kubernetes/changeset/:cluster
  def index
    render json: @audits
  end

  private

  def load_audits
    @audits = Kubernetes::ChangesetService.get_events(params[:cluster])
  end
end
