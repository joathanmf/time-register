module Api
  module V1
    class ReportsController < ApplicationController
      before_action :set_report_process, only: [ :status, :download ]

      def status
        render json: {
          process_id: @report_process.process_id,
          status: @report_process.status,
          progress: @report_process.progress
        }
      end

      def download
        unless @report_process.file_ready?
          return render json: {
            error: "Report not ready. Status: #{@report_process.status}"
          }, status: :unprocessable_entity
        end

        send_data @report_process.file.download,
                  filename: "report_#{@report_process.process_id}.csv",
                  type: "text/csv",
                  disposition: "attachment"
      rescue StandardError => e
        render json: { error: "Error downloading: #{e.message}" },
               status: :internal_server_error
      end

      private

      def set_report_process
        @report_process = ReportProcess.find_by!(process_id: params[:process_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Report not found" }, status: :not_found
      end
    end
  end
end
