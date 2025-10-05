module Reports
  class CsvReport < BaseReport
    private

    def build_content
      Reports::Builders::CsvBuilder.new(report_process).build
    end
  end
end
