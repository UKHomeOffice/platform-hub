class Kubernetes::ChangesetController < ApiJsonController

  before_action :load_changeset

  # GET /kubernetes/changeset/:cluster
  def index
    authorize! :read, :changeset
    render json: @changeset, each_serializer: AuditSerializer
  end

  private

  def load_changeset
    since = Kubernetes::ChangesetService.last_sync(params[:cluster])
    @changeset = Kubernetes::ChangesetService.get_events(params[:cluster], since)
  end
end
