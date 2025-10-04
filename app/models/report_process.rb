# == Schema Information
#
# Table name: report_processes
#
#  id            :bigint           not null, primary key
#  end_date      :date             not null
#  error_message :text
#  progress      :integer          default(0)
#  start_date    :date             not null
#  status        :string           default("queued"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  process_id    :string           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_report_processes_on_process_id  (process_id) UNIQUE
#  index_report_processes_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ReportProcess < ApplicationRecord
  belongs_to :user

  has_one_attached :csv_file

  enum :status, { queued: "queued", processing: "processing", completed: "completed", failed: "failed" }, prefix: true

  validates :process_id, presence: true, uniqueness: true
  validates :start_date, :end_date, presence: true
  validates :status, presence: true

  validate :end_date_after_start_date

  before_validation :generate_process_id, on: :create

  def mark_as_processing!
    update!(status: :processing, progress: 0)
  end

  def mark_as_completed!(file_io)
    csv_file.attach(
      io: file_io,
      filename: "report_#{process_id}.csv",
      content_type: "text/csv"
    )

    update!(
      status: :completed,
      progress: 100,
      error_message: nil
    )
  end

  def mark_as_failed!(error)
    update!(
      status: :failed,
      error_message: error.message,
      progress: 0
    )
  end

  def update_progress!(percentage)
    update!(progress: percentage.clamp(0, 100))
  end

  def file_ready?
    status_completed? && csv_file.attached?
  end

  def file_size
    return 0 unless csv_file.attached?
    csv_file.byte_size
  end

  private

  def end_date_after_start_date
    return if end_date.nil? || start_date.nil?

    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def generate_process_id
    self.process_id ||= SecureRandom.uuid
  end
end
