module Reports
  class BaseReport
    def initialize(report_process)
      @report_process = report_process
    end

    def generate
      report_process.mark_as_processing!

      content = build_content
      attach_file(content)

      report_process.reload
    rescue StandardError => e
      report_process.mark_as_failed!(e)
      raise
    end

    private

    attr_reader :report_process

    def build_content
      raise NotImplementedError, "Subclasses must implement #build_content"
    end

    def attach_file(content)
      file_io = StringIO.new(content)
      report_process.mark_as_completed!(file_io)
    end
  end
end
