module Costs
  module ProjectBillsQueryService
    extend self

    def fetch project_id
      # Don't allow } and ' as they can be used for SQL injection in this particular case
      raise ArgumentError if project_id.count("}'") > 0

      entries = CostsReport
        .published
        .select("costs_reports.year, costs_reports.month, costs_reports.results #> '{project_bills,#{project_id}}' as project_bill")
        .order(id: :desc)
        .entries

      entries.each_with_object([]) do |e, acc|
        if e.project_bill.present?
          acc << {
            year: e.year,
            month: e.month,
            bills: e.project_bill['bills']
          }
        end
      end
    end
  end
end
