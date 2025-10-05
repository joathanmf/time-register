module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, except: [ :index, :create ]

      def index
        users = User.all
        render json: users
      end

      def show
        render json: @user
      end

      def create
        user = User.new(user_params)

        if user.save
          render json: user, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @user.update(user_params)
          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @user.destroy
          head :no_content
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def time_registers
        time_registers = @user.clockings
        render json: time_registers
      end

      def reports
        start_date = params[:start_date]
        end_date = params[:end_date]
        report_process = @user.report_processes.new(start_date: start_date, end_date: end_date)

        if report_process.save
          GenerateReportJob.perform_later(report_process.id)

          render json: {
            process_id: report_process.process_id,
            status: report_process.status
          }, status: :accepted
        else
          render json: {
            errors: report_process.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email)
      end

      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end
    end
  end
end
