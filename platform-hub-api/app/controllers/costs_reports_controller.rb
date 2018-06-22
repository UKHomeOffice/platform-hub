require 'csv'

class CostsReportsController < ApiJsonController

  extend Memoist

  S3_OBJECT_PREFIX = 'costs'

  before_action :find_report, only: [ :show, :destroy, :publish ]

  authorize_resource

  # GET /costs_reports/available_data_files
  def available_data_files
    entries = filestore_service.names
    render json: entries
  end

  # GET /costs_reports
  def index
    reports = CostsReport.order(id: :desc)
    render json: reports, fields: [ :id, :year, :month, :billing_file, :metrics_file, :notes, :created_at, :published_at ]
  end

  # GET /costs_reports/:id
  def show
    render json: @report
  end

  # POST /costs_reports/prepare
  def prepare
    params = self.params.require(:costs_report)
    year = params.require('year')
    month = params.require('month')

    unless CostsReport.is_valid_month_abbr?(month)
      invalid_month_error and return
    end

    results = Costs::ReportResultsGeneratorService.new(
      billing_data_service,
      metrics_data_service,
      project_lookup_cache_service,
      project_service_name_lookup_cache_service
    ).prepare_results

    results[:exists] = CostsReport.exists_for? year, month
    results[:already_published] = CostsReport.already_published? year, month

    render json: results
  end

  # POST /costs_reports
  def create
    params = report_params.to_h

    year = params[:year]
    month = params[:month]

    unless CostsReport.is_valid_month_abbr?(month)
      invalid_month_error and return
    end

    if CostsReport.already_published?(year, month)
      render_error('Report already exists and is published - cannot overwrite', :unprocessable_entity) and return
    end

    results = Costs::ReportResultsGeneratorService.new(
      billing_data_service,
      metrics_data_service,
      project_lookup_cache_service,
      project_service_name_lookup_cache_service
    ).report_results(params[:config])

    # Now that we have the results, delete an existing report if it exists
    CostsReport.by_year_and_month(year, month).delete_all

    report = CostsReport.new(params)
    report.results = results

    if report.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: report,
        data: { id: report.id }
      )

      render json: report, status: :created
    else
      render_model_errors report.errors
    end
  end

  # DELETE /costs_reports/:id
  def destroy
    if @report.published?
      # IMPORTANT: for published reports, we call `.delete` here to directly
      # delete the entry in the db, in order to bypass the readonly checks.
      # This does mean that any callbacks and association deletions are not
      # taken care of.
      @report.delete
    else
      @report.destroy!
    end

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @report,
      data: { id: @report.id },
      comment: "User '#{current_user.email}' deleted costs report: '#{@report.id}'"
    )

    head :no_content
  end

  # POST /costs_reports/:id/publish
  def publish
    @report.publish!

    AuditService.log(
      context: audit_context,
      action: 'publish',
      auditable: @report,
      data: { id: @report.id }
    )

    render json: @report
  end

  def last_published_config
    report = CostsReport
      .where.not(published_at: nil)
      .order(published_at: :desc)
      .first

    render json: report.try(:config) || {}
  end

  private

  def find_report
    @report = CostsReport.find params[:id]
  end

  def report_params
    allowed_params = params.require(:costs_report).permit(
      :year,
      :month,
      :notes,
      :billing_file,
      :metrics_file
    )

    # Below is a workaround until Rails 5.1 lands and we can use the `foo: [{}]` syntax to permit the whole array of hashes
    allowed_params[:config] = params[:costs_report][:config]
    allowed_params.permit!
  end

  def invalid_month_error
    render_error 'Invalid month specified', :unprocessable_entity
  end

  memoize def billing_data_service
    data = CSV.parse(
      filestore_service.get(
        params.require('billing_file')
      )
    )

    Costs::BillingDataService.new(
      data,
      cluster_lookup_cache_service,
      namespace_lookup_cache_service,
      project_lookup_cache_service
    )
  end

  memoize def metrics_data_service
    data = CSV.parse(
      filestore_service.get(
        params.require('metrics_file')
      )
    )

    Costs::MetricsDataService.new(
      data,
      cluster_lookup_cache_service,
      namespace_lookup_cache_service
    )
  end

  memoize def cluster_lookup_cache_service
    Kubernetes::ClusterLookupCacheService.new
  end

  memoize def namespace_lookup_cache_service
    Kubernetes::NamespaceLookupCacheService.new
  end

  memoize def project_lookup_cache_service
    ProjectLookupCacheService.new
  end

  memoize def project_service_name_lookup_cache_service
    ProjectServiceNameLookupCacheService.new
  end

  memoize def filestore_service
    FilestoreService.new(
      s3_region: Rails.application.secrets.filestore_s3_region,
      s3_bucket_name: Rails.application.secrets.filestore_s3_bucket_name,
      s3_access_key_id: Rails.application.secrets.filestore_s3_access_key_id,
      s3_secret_access_key: Rails.application.secrets.filestore_s3_secret_access_key,
      s3_object_prefix: S3_OBJECT_PREFIX
    )
  end

end
