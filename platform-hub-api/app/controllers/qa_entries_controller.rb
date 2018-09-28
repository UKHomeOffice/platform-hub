class QaEntriesController < ApiJsonController

  before_action :find_qa_entry, only: [:show, :update, :destroy]

  authorize_resource

  # GET /qa_entries
  def index
    @qa_entries = QaEntry.order(:question)

    render json: @qa_entries
  end

  # GET /qa_entries/1
  def show
    render json: @qa_entry
  end

  # POST /qa_entries
  def create
    @qa_entry = QaEntry.new(qa_entry_params)

    if @qa_entry.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: @qa_entry
      )

      render json: @qa_entry, status: :created
    else
      render_model_errors @qa_entry.errors
    end
  end

  # PATCH/PUT /qa_entries/1
  def update
    if @qa_entry.update(qa_entry_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @qa_entry
      )

      render json: @qa_entry
    else
      render_model_errors @qa_entry.errors
    end
  end

  # DELETE /qa_entries/1
  def destroy
    id = @qa_entry.id
    question = @qa_entry.question

    @qa_entry.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @qa_entry,
      comment: "User '#{current_user.email}' deleted Q&A entry: '#{question}' (ID: #{id})"
    )

    head :no_content
  end

  private

  def find_qa_entry
    @qa_entry = QaEntry.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def qa_entry_params
    params.require(:qa_entry).permit(:question, :answer)
  end

end
