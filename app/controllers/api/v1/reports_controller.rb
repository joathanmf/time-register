module Api
  module V1
    class ReportsController < ApplicationController
      before_action :set_report_process, only: [ :status, :download ]

      def status
        render json: {
          process_id: @report_process.process_id,
          status: @report_process.status,
          progress: @report_process.progress,
          file_size: @report_process.file_size,
          file_ready: @report_process.file_ready?,
          created_at: @report_process.created_at,
          updated_at: @report_process.updated_at,
          error_message: @report_process.error_message
        }
      end

      def download
        unless @report_process.status_completed?
          return render json: {
            error: "Report not ready yet",
            status: @report_process.status
          }, status: :unprocessable_entity
        end

        unless @report_process.csv_file.attached?
          return render json: {
            error: "Report file not found"
          }, status: :not_found
        end

        redirect_to rails_blob_path(@report_process.csv_file, disposition: "attachment"), allow_other_host: true
      end

      private

      def set_report_process
        @report_process = ReportProcess.find_by!(process_id: params[:process_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Report process not found" }, status: :not_found
      end
    end
  end
end
