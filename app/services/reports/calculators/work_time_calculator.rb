module Reports
  module Calculators
    class WorkTimeCalculator
      def initialize
        @formatter = Reports::Formatters::DateTimeFormatter.new
      end

      def hours_worked(clocking)
        formatter.duration(seconds_worked(clocking))
      end

      def total_hours(clockings)
        total = clockings.sum { |c| seconds_worked(c) }
        formatter.duration(total)
      end

      def seconds_worked(clocking)
        return 0 if clocking.clock_in.blank? || clocking.clock_out.blank?
        (clocking.clock_out - clocking.clock_in).to_i
      end

      private

      attr_reader :formatter
    end
  end
end
