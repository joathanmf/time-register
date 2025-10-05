require 'rails_helper'

RSpec.describe Reports::CsvReport, type: :service do
  let(:user) { create(:user) }
  let(:report_process) { create(:report_process, user: user, start_date: Date.today - 7.days, end_date: Date.today) }

  describe '#generate' do
    subject { described_class.new(report_process) }

    context 'with clockings data' do
      before do
        create_list(:clocking, 3, :completed, user: user, clock_in: 3.days.ago)
        # Skip the sleep for tests
        allow_any_instance_of(Reports::Builders::CsvBuilder).to receive(:sleep)
      end

      it 'generates the report successfully' do
        expect { subject.generate }.not_to raise_error
      end

      it 'marks report as completed' do
        subject.generate

        expect(report_process.reload.status).to eq('completed')
      end

      it 'attaches CSV file' do
        subject.generate

        expect(report_process.reload.file.attached?).to be true
        expect(report_process.file.content_type).to eq('text/csv')
      end
    end

    context 'without clockings data' do
      before do
        allow_any_instance_of(Reports::Builders::CsvBuilder).to receive(:sleep)
      end

      it 'generates empty report' do
        expect { subject.generate }.not_to raise_error
      end

      it 'still completes successfully' do
        subject.generate

        expect(report_process.reload.status).to eq('completed')
      end
    end

    context 'when builder raises error' do
      before do
        allow_any_instance_of(Reports::Builders::CsvBuilder).to receive(:build).and_raise(StandardError.new('CSV error'))
      end

      it 'marks report as failed' do
        expect { subject.generate }.to raise_error(StandardError)

        expect(report_process.reload.status).to eq('failed')
      end

      it 'stores error message' do
        expect { subject.generate }.to raise_error(StandardError)

        expect(report_process.reload.error_message).to eq('CSV error')
      end
    end
  end
end
