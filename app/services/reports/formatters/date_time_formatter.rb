module Reports
  module Formatters
    class DateTimeFormatter
      def date(datetime)
        return "-" if datetime.blank?
        datetime.in_time_zone.strftime("%d/%m/%Y")
      end

      def weekday(datetime)
        return "-" if datetime.blank?
        I18n.l(datetime.in_time_zone, format: "%A")
      rescue
        datetime.in_time_zone.strftime("%A")
      end

      def time(datetime)
        return "-" if datetime.blank?
        datetime.in_time_zone.strftime("%H:%M:%S")
      end

      def duration(seconds)
        return "-" if seconds.zero?
        hours = seconds / 3600
        minutes = (seconds % 3600) / 60
        "#{hours}h #{minutes}min"
      end
    end
  end
end
