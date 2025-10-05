require 'rails_helper'

RSpec.describe Reports::GenerateJob, type: :job do
  let(:user) { create(:user) }
  let(:report_process) { create(:report_process, user: user) }

  describe '#perform' do
    context 'with valid report process' do
      before do
        allow_any_instance_of(Reports::Builders::CsvBuilder).to receive(:sleep)
      end

      it 'processes the report successfully' do
        expect {
          described_class.perform_now(report_process.id)
        }.not_to raise_error
      end

      it 'marks report as completed' do
        described_class.perform_now(report_process.id)

        expect(report_process.reload.status).to eq('completed')
      end

      it 'attaches the file' do
        described_class.perform_now(report_process.id)

        expect(report_process.reload.file.attached?).to be true
      end

      it 'uses csv report type by default' do
        expect(Reports::ReportFactory).to receive(:create).with(:csv, report_process).and_call_original

        described_class.perform_now(report_process.id)
      end

      it 'accepts custom report type' do
        expect(Reports::ReportFactory).to receive(:create).with(:custom, report_process).and_call_original

        expect {
          described_class.perform_now(report_process.id, report_type: :custom)
        }.to raise_error(ArgumentError) # Because :custom doesn't exist
      end
    end

    context 'when report process does not exist' do
      it 'discards the job' do
        expect {
          described_class.perform_now(999999)
        }.not_to raise_error
      end
    end

    context 'when generation fails' do
      it 're-raises the error for retry' do
        allow_any_instance_of(Reports::CsvReport).to receive(:generate).and_raise(StandardError.new('Generation error'))

        expect {
          described_class.perform_now(report_process.id)
        }.to raise_error(StandardError, 'Generation error')
      end
    end

    context 'job configuration' do
      it 'is queued in reports queue' do
        expect(described_class.new.queue_name).to eq('reports')
      end
    end
  end

  describe 'enqueuing' do
    it 'enqueues the job with correct arguments' do
      expect {
        described_class.perform_later(report_process.id)
      }.to have_enqueued_job(described_class).with(report_process.id)
    end

    it 'enqueues the job in the reports queue' do
      expect {
        described_class.perform_later(report_process.id)
      }.to have_enqueued_job.on_queue('reports')
    end
  end
end
