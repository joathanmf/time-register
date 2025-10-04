require "csv"

class ReportGeneratorService
  attr_reader :report_process

  def initialize(report_process)
    @report_process = report_process
  end

  def call
    report_process.mark_as_processing!

    csv_data = generate_csv_data
    attach_csv_file(csv_data)

    report_process.reload
  rescue StandardError => e
    report_process.mark_as_failed!(e)
    raise
  end

  private

  def generate_csv_data
    CSV.generate(headers: true) do |csv|
      csv << csv_headers

      clockings_batch.each_with_index do |clocking, index|
        csv << build_csv_row(clocking)
        update_progress(index + 1, total_clockings)
      end

      csv << build_summary_row
    end
  end

  def attach_csv_file(csv_data)
    file_io = StringIO.new(csv_data)
    report_process.mark_as_completed!(file_io)
  end

  def csv_headers
    [
      "Data",
      "Dia da Semana",
      "Entrada",
      "Saída",
      "Horas Trabalhadas",
      "Status",
      "Observações"
    ]
  end

  def build_csv_row(clocking)
    [
      format_date(clocking.clock_in),
      format_weekday(clocking.clock_in),
      format_time(clocking.clock_in),
      format_time(clocking.clock_out),
      calculate_hours_worked(clocking),
      clocking_status(clocking),
      clocking_observations(clocking)
    ]
  end

  def build_summary_row
    [
      "",
      "TOTAL",
      "",
      "",
      format_total_hours,
      "#{total_complete_clockings} registros completos",
      "#{total_open_clockings} registros abertos"
    ]
  end

  # ==========================================
  # Formatação
  # ==========================================

  def format_date(datetime)
    return "-" if datetime.blank?
    datetime.in_time_zone.strftime("%d/%m/%Y")
  end

  def format_weekday(datetime)
    return "-" if datetime.blank?
    I18n.l(datetime.in_time_zone, format: "%A")
  rescue
    datetime.in_time_zone.strftime("%A")
  end

  def format_time(datetime)
    return "-" if datetime.blank?
    datetime.in_time_zone.strftime("%H:%M:%S")
  end

  def format_total_hours
    total_seconds = clockings_batch.sum { |c| calculate_seconds_worked(c) }
    format_duration(total_seconds)
  end

  def format_duration(seconds)
    return "-" if seconds.zero?

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    "#{hours}h #{minutes}min"
  end

  # ==========================================
  # Cálculos
  # ==========================================

  def calculate_hours_worked(clocking)
    seconds = calculate_seconds_worked(clocking)
    return "-" if seconds.zero?

    format_duration(seconds)
  end

  def calculate_seconds_worked(clocking)
    return 0 if clocking.clock_in.blank? || clocking.clock_out.blank?

    (clocking.clock_out - clocking.clock_in).to_i
  end

  def clocking_status(clocking)
    if clocking.clock_out.blank?
      "Aberto"
    else
      duration = calculate_seconds_worked(clocking)

      case duration
      when 0..14400 # Menos de 4 horas
        "Parcial"
      when 14400..28800 # 4-8 horas
        "Normal"
      when 28800..32400 # 8-9 horas
        "Completo"
      else # Mais de 9 horas
        "Hora Extra"
      end
    end
  end

  def clocking_observations(clocking)
    observations = []

    if clocking.clock_out.blank?
      observations << "Ponto não fechado"
    else
      duration = calculate_seconds_worked(clocking)

      if duration < 14400 # Menos de 4 horas
        observations << "Jornada incompleta"
      elsif duration > 36000 # Mais de 10 horas
        observations << "Jornada excessiva"
      end

      # Verificar se saiu muito tarde ou muito cedo
      clock_in_hour = clocking.clock_in.hour
      clock_out_hour = clocking.clock_out.hour

      observations << "Entrada tardia" if clock_in_hour > 9
      observations << "Saída antecipada" if clock_out_hour < 17
    end

    observations.join("; ")
  end

  # ==========================================
  # Queries
  # ==========================================

  def clockings_batch
    @clockings_batch ||= report_process.user
                                       .clockings
                                       .where("clock_in >= ? AND clock_in <= ?",
                                              start_datetime,
                                              end_datetime)
                                       .order(:clock_in)
                                       .to_a
  end

  def total_clockings
    @total_clockings ||= clockings_batch.count
  end

  def total_complete_clockings
    clockings_batch.count { |c| c.clock_out.present? }
  end

  def total_open_clockings
    clockings_batch.count { |c| c.clock_out.blank? }
  end

  # ==========================================
  # Helpers
  # ==========================================

  def start_datetime
    @start_datetime ||= report_process.start_date.beginning_of_day
  end

  def end_datetime
    @end_datetime ||= report_process.end_date.end_of_day
  end

  def update_progress(current, total)
    return if total.zero?

    percentage = ((current.to_f / total) * 100).round
    report_process.update_progress!(percentage)
  end
end
