module Reports
  class GenerateJob < ApplicationJob
    queue_as :reports

    sidekiq_options retry: 3, backtrace: true
    discard_on ActiveRecord::RecordNotFound

    def perform(report_process_id, report_type: :csv)
      report_process = ReportProcess.find(report_process_id)

      report = Reports::ReportFactory.create(report_type, report_process)
      report.generate
    rescue StandardError
      raise
    end
  end
end
