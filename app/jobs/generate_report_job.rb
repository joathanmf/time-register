class GenerateReportJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  discard_on ActiveRecord::RecordNotFound

  def perform(report_process_id)
    report_process = ReportProcess.find(report_process_id)

    Rails.logger.info("Starting report generation for process: #{report_process.process_id}")

    ReportGeneratorService.new(report_process).call

    Rails.logger.info("Report generation completed for process: #{report_process.process_id}")
  rescue StandardError => e
    Rails.logger.error("Report generation job failed: #{e.message}")
    raise
  end
end
