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
require 'rails_helper'

RSpec.describe ReportProcess, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_one_attached(:file) }
  end

  describe 'validations' do
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:status) }

    context 'process_id uniqueness' do
      let(:user) { create(:user) }

      it 'validates uniqueness of process_id' do
        create(:report_process, user: user, process_id: 'unique-id')
        duplicate = build(:report_process, user: user, process_id: 'unique-id')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:process_id]).to include('has already been taken')
      end

      it 'generates process_id automatically' do
        report = create(:report_process, user: user)

        expect(report.process_id).to be_present
        expect(report.process_id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
      end
    end

    context 'end_date_after_start_date validation' do
      let(:user) { create(:user) }

      it 'is valid when end_date is after start_date' do
        report = build(:report_process,
          user: user,
          start_date: Date.today,
          end_date: Date.today + 7.days
        )

        expect(report).to be_valid
      end

      it 'is valid when end_date equals start_date' do
        date = Date.today
        report = build(:report_process,
          user: user,
          start_date: date,
          end_date: date
        )

        expect(report).to be_valid
      end

      it 'is invalid when end_date is before start_date' do
        report = build(:report_process,
          user: user,
          start_date: Date.today,
          end_date: Date.today - 1.day
        )

        expect(report).not_to be_valid
        expect(report.errors[:end_date]).to include('must be after start date')
      end
    end
  end

  describe 'callbacks' do
    describe 'generate_process_id' do
      let(:user) { create(:user) }

      it 'generates a process_id before validation on create' do
        report = ReportProcess.new(
          user: user,
          start_date: Date.today,
          end_date: Date.today + 7.days
        )

        expect(report.process_id).to be_nil
        report.valid?
        expect(report.process_id).to be_present
        expect(report.process_id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
      end

      it 'does not override existing process_id' do
        custom_id = 'custom-process-id'
        report = ReportProcess.new(
          user: user,
          process_id: custom_id,
          start_date: Date.today,
          end_date: Date.today + 7.days
        )

        report.valid?
        expect(report.process_id).to eq(custom_id)
      end
    end
  end

  describe 'enums' do
    it 'defines status enum correctly' do
      expect(ReportProcess.statuses).to eq({
        'queued' => 'queued',
        'processing' => 'processing',
        'completed' => 'completed',
        'failed' => 'failed'
      })
    end
  end

  describe '#mark_as_processing!' do
    let(:report_process) { create(:report_process) }

    it 'updates status to processing and resets progress' do
      report_process.update(status: :queued, progress: 50)

      report_process.mark_as_processing!

      expect(report_process.reload.status).to eq('processing')
      expect(report_process.progress).to eq(0)
    end
  end

  describe '#mark_as_completed!' do
    let(:report_process) { create(:report_process) }
    let(:file_io) { StringIO.new('test,data\n1,2') }

    it 'attaches file and updates status to completed' do
      report_process.mark_as_completed!(file_io)

      expect(report_process.reload.status).to eq('completed')
      expect(report_process.progress).to eq(100)
      expect(report_process.file.attached?).to be true
      expect(report_process.error_message).to be_nil
    end

    it 'sets correct filename' do
      report_process.mark_as_completed!(file_io)

      expect(report_process.file.filename.to_s).to eq("report_#{report_process.process_id}.csv")
    end

    it 'sets correct content type' do
      report_process.mark_as_completed!(file_io)

      expect(report_process.file.content_type).to eq('text/csv')
    end
  end

  describe '#mark_as_failed!' do
    let(:report_process) { create(:report_process, status: :processing, progress: 50) }
    let(:error) { StandardError.new('Something went wrong') }

    it 'updates status to failed and stores error message' do
      report_process.mark_as_failed!(error)

      expect(report_process.reload.status).to eq('failed')
      expect(report_process.error_message).to eq('Something went wrong')
      expect(report_process.progress).to eq(0)
    end
  end

  describe '#update_progress!' do
    let(:report_process) { create(:report_process) }

    it 'updates progress with valid percentage' do
      report_process.update_progress!(75)

      expect(report_process.reload.progress).to eq(75)
    end

    it 'clamps progress to 0 if negative' do
      report_process.update_progress!(-10)

      expect(report_process.reload.progress).to eq(0)
    end

    it 'clamps progress to 100 if over 100' do
      report_process.update_progress!(150)

      expect(report_process.reload.progress).to eq(100)
    end
  end

  describe '#file_ready?' do
    let(:report_process) { create(:report_process) }

    it 'returns true when status is completed and file is attached' do
      file_io = StringIO.new('test,data')
      report_process.mark_as_completed!(file_io)

      expect(report_process.file_ready?).to be true
    end

    it 'returns false when status is completed but file is not attached' do
      report_process.update(status: :completed)

      expect(report_process.file_ready?).to be false
    end

    it 'returns false when file is attached but status is not completed' do
      report_process.file.attach(
        io: StringIO.new('test'),
        filename: 'test.csv',
        content_type: 'text/csv'
      )
      report_process.update(status: :processing)

      expect(report_process.file_ready?).to be false
    end
  end

  describe '#file_size' do
    let(:report_process) { create(:report_process) }

    it 'returns file size when file is attached' do
      content = 'test,data\n1,2'
      file_io = StringIO.new(content)
      report_process.mark_as_completed!(file_io)

      expect(report_process.file_size).to eq(content.bytesize)
    end

    it 'returns 0 when file is not attached' do
      expect(report_process.file_size).to eq(0)
    end
  end
end
