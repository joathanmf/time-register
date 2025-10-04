module Api
  module V1
    class TimeRegistersController < ApplicationController
      before_action :set_time_register, except: [ :index, :create ]

      def index
        time_registers = Clocking.all
        render json: time_registers
      end

      def show
        render json: @time_registers
      end

      def create
        time_register = Clocking.new(time_register_params)

        if time_register.save
          render json: time_register, status: :created
        else
          render json: { errors: time_register.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @time_registers.update(time_register_params)
          render json: @time_registers
        else
          render json: { errors: @time_registers.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @time_registers.destroy
          head :no_content
        else
          render json: { errors: @time_registers.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def time_register_params
        params.require(:time_register).permit(:user_id, :clock_in, :clock_out)
      end

      def set_time_register
        @time_registers = Clocking.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Time register not found" }, status: :not_found
      end
    end
  end
end
