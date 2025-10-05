module Reports
  class CreateService
    Result = Struct.new(:success?, :report_process, :errors, keyword_init: true)

    def self.call(**args)
      new(**args).call
    end

    def initialize(user:, start_date:, end_date:)
      @user = user
      @start_date = start_date
      @end_date = end_date
    end

    def call
      report_process = user.report_processes.new(
        start_date: Date.parse(start_date.to_s),
        end_date: Date.parse(end_date.to_s)
      )

      if report_process.save
        Reports::GenerateJob.perform_later(report_process.id)
        Result.new(success?: true, report_process: report_process)
      else
        Result.new(success?: false, errors: report_process.errors.full_messages)
      end
    rescue ArgumentError => e
      Result.new(success?: false, errors: [ e.message ])
    end

    private

    attr_reader :user, :start_date, :end_date
  end
end
