class CostsReportsController < ApiJsonController

  S3_OBJECT_PREFIX = 'costs'

  before_action :find_report, only: [ :show, :destroy ]

  authorize_resource

  # GET /costs_reports/available_data_files
  def available_data_files
    entries = filestore_service.names
    render json: entries
  end

  # GET /costs_reports
  def index
    reports = CostsReport.order(id: :desc)
    render json: reports, fields: [ :id, :year, :month, :billing_file, :metrics_file, :notes, :created_at ]
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
    billing_file = params.require('billing_file')
    metrics_file = params.require('metrics_file')

    unless CostsReport.is_valid_month_abbr?(month)
      invalid_month_error and return
    end

    billing_csv_string = filestore_service.get(billing_file)
    metrics_csv_string = filestore_service.get(metrics_file)

    results, _, _ = CostsReportGeneratorService.prepare(
      year: year,
      month: month,
      billing_csv_string: billing_csv_string,
      metrics_csv_string: metrics_csv_string
    )

    results[:exists] = CostsReport.exists_for? year, month

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

    billing_csv_string = filestore_service.get(params[:billing_file])
    metrics_csv_string = filestore_service.get(params[:metrics_file])

    results = CostsReportGeneratorService.build(
      year: year,
      month: month,
      notes: params[:notes],
      billing_csv_string: billing_csv_string,
      metrics_csv_string: metrics_csv_string,
      config: params[:config]
    )

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
    @report.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @report,
      data: { id: @report.id },
      comment: "User '#{current_user.email}' deleted costs report: '#{@report.id}'"
    )

    head :no_content
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

  def filestore_service
    @filestore_service ||= FilestoreService.new(
      s3_region: Rails.application.secrets.filestore_s3_region,
      s3_bucket_name: Rails.application.secrets.filestore_s3_bucket_name,
      s3_access_key_id: Rails.application.secrets.filestore_s3_access_key_id,
      s3_secret_access_key: Rails.application.secrets.filestore_s3_secret_access_key,
      s3_object_prefix: S3_OBJECT_PREFIX
    )
  end

end
