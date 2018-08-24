class DocsSourcesController < ApiJsonController

  before_action :find_docs_source, only: [ :show, :update, :destroy ]

  authorize_resource

  # GET /docs_sources
  def index
    @docs_sources = DocsSource.order(:name)

    render json: @docs_sources
  end

  # GET /docs_sources/1
  def show
    render json: @docs_source
  end

  # POST /docs_sources
  def create
    @docs_source = DocsSource.new(docs_source_params)

    if @docs_source.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: @docs_source
      )

      render json: @docs_source, status: :created
    else
      render_model_errors @docs_source.errors
    end
  end

  # PATCH/PUT /docs_sources/1
  def update
    if @docs_source.update(docs_source_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @docs_source
      )

      render json: @docs_source
    else
      render_model_errors @docs_source.errors
    end
  end

  # DELETE /docs_sources/1
  def destroy
    id = @docs_source.id
    name = @docs_source.name

    # Clean up docs in the help search index
    @docs_source.entries.each do |entry|
      HelpSearchService.instance.delete_item entry
    end

    @docs_source.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @docs_source,
      comment: "User '#{current_user.email}' deleted docs source: '#{name}' (ID: #{id})"
    )

    head :no_content
  end

  private

  def find_docs_source
    @docs_source = DocsSource.find params[:id]
  end

  # Only allow a trusted parameter "white list" through.
  def docs_source_params
    allowed_params = params.require(:docs_source).permit(:kind, :name)

    # Below is a workaround until Rails 5.1 lands and we can use the `foo: {}` syntax to permit the whole hash
    if params[:docs_source][:config]
      allowed_params[:config] = params[:docs_source][:config]
    end

    allowed_params.permit!
  end

end
