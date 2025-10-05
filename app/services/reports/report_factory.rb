module Reports
  class ReportFactory
    def self.create(type, report_process)
      case type.to_sym
      when :csv
        Reports::CsvReport.new(report_process)
      else
        raise ArgumentError, "Unknown report type: #{type}"
      end
    end
  end
end
