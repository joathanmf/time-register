require "csv"

module Reports
  module Builders
    class CsvBuilder
      HEADERS = [
        "Data", "Dia da Semana", "Entrada", "Saída",
        "Horas Trabalhadas", "Status", "Observações"
      ].freeze

      def initialize(report_process)
        @report_process = report_process
        @formatter = Reports::Formatters::DateTimeFormatter.new
        @calculator = Reports::Calculators::WorkTimeCalculator.new
        @clockings = fetch_clockings
      end

      def build
        # sleep 15 # Simula um processamento demorado

        CSV.generate(headers: true) do |csv|
          add_headers(csv)
          add_data_rows(csv)
          add_summary_row(csv)
        end
      end

      private

      attr_reader :report_process, :formatter, :calculator, :clockings

      def add_headers(csv)
        csv << HEADERS
      end

      def add_data_rows(csv)
        clockings.each_with_index do |clocking, index|
          csv << build_row(clocking)
          update_progress(index + 1)
        end
      end

      def add_summary_row(csv)
        csv << [
          "", "TOTAL", "", "",
          calculator.total_hours(clockings),
          "#{complete_count} registros completos",
          "#{open_count} registros abertos"
        ]
      end

      def build_row(clocking)
        [
          formatter.date(clocking.clock_in),
          formatter.weekday(clocking.clock_in),
          formatter.time(clocking.clock_in),
          formatter.time(clocking.clock_out),
          calculator.hours_worked(clocking)
        ]
      end

      def fetch_clockings
        report_process.user
          .clockings
          .where(clock_in: date_range)
          .order(:clock_in)
          .to_a
      end

      def date_range
        report_process.start_date.beginning_of_day..report_process.end_date.end_of_day
      end

      def complete_count
        clockings.count(&:clock_out?)
      end

      def open_count
        clockings.count { |c| c.clock_out.blank? }
      end

      def update_progress(current)
        return if clockings.count.zero?

        percentage = ((current.to_f / clockings.count) * 100).round
        report_process.update_progress!(percentage)
      end
    end
  end
end
