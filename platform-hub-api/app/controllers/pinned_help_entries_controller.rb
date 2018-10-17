class PinnedHelpEntriesController < ApiJsonController

  LIST_NAME = 'default'

  before_action :load_pinned_help_entries_hash_record

  skip_authorization_check only: [ :show ]

  # GET /pinned_help_entries
  def show
    render json: entries
  end

  # PUT /pinned_help_entries
  def update
    authorize! :manage, :pinned_help_entries

    data = @pinned_help_entries.data.merge({
        LIST_NAME => params[:pinned_help_entry][:_json]
    })

    if @pinned_help_entries.update(data: data)
      AuditService.log(
        context: audit_context,
        action: 'update_pinned_help_entries'
      )

      render json: entries
    else
      render @pinned_help_entries
    end
  end

  private

  def load_pinned_help_entries_hash_record
    @pinned_help_entries = HashRecord.webapp.find_or_create_by!(id: 'pinned_help_entries') do |r|
      r.data = {
        LIST_NAME => []
      }
    end
  end

  def entries
    @pinned_help_entries.data[LIST_NAME]
  end

end
