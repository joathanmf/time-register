require 'rails_helper'

RSpec.describe Reports::ReportFactory, type: :service do
  let(:user) { create(:user) }
  let(:report_process) { create(:report_process, user: user) }

  describe '.create' do
    context 'with csv type' do
      it 'returns CsvReport instance' do
        report = described_class.create(:csv, report_process)

        expect(report).to be_a(Reports::CsvReport)
      end

      it 'accepts string type' do
        report = described_class.create('csv', report_process)

        expect(report).to be_a(Reports::CsvReport)
      end
    end

    context 'with unknown type' do
      it 'raises ArgumentError' do
        expect {
          described_class.create(:pdf, report_process)
        }.to raise_error(ArgumentError, 'Unknown report type: pdf')
      end

      it 'raises ArgumentError for invalid string' do
        expect {
          described_class.create('unknown', report_process)
        }.to raise_error(ArgumentError, 'Unknown report type: unknown')
      end
    end
  end
end
require 'rails_helper'

RSpec.describe Reports::CreateService, type: :service do
  let(:user) { create(:user) }
  let(:start_date) { '2024-01-01' }
  let(:end_date) { '2024-01-31' }

  describe '.call' do
    context 'with valid parameters' do
      it 'creates a report process successfully' do
        expect {
          described_class.call(user: user, start_date: start_date, end_date: end_date)
        }.to change(ReportProcess, :count).by(1)
      end

      it 'returns success result' do
        result = described_class.call(user: user, start_date: start_date, end_date: end_date)

        expect(result.success?).to be true
        expect(result.report_process).to be_a(ReportProcess)
        expect(result.errors).to be_nil
      end

      it 'enqueues a generate job' do
        expect {
          described_class.call(user: user, start_date: start_date, end_date: end_date)
        }.to have_enqueued_job(Reports::GenerateJob)
      end

      it 'sets correct dates on report process' do
        result = described_class.call(user: user, start_date: start_date, end_date: end_date)

        expect(result.report_process.start_date).to eq(Date.parse(start_date))
        expect(result.report_process.end_date).to eq(Date.parse(end_date))
      end

      it 'accepts Date objects as parameters' do
        result = described_class.call(
          user: user,
          start_date: Date.parse(start_date),
          end_date: Date.parse(end_date)
        )

        expect(result.success?).to be true
      end
    end

    context 'with invalid parameters' do
      it 'returns failure result with invalid date format' do
        result = described_class.call(user: user, start_date: 'invalid', end_date: 'invalid')

        expect(result.success?).to be false
        expect(result.errors).to be_present
        expect(result.report_process).to be_nil
      end

      it 'does not create report process with invalid dates' do
        expect {
          described_class.call(user: user, start_date: 'invalid', end_date: 'invalid')
        }.not_to change(ReportProcess, :count)
      end

      it 'returns failure when end_date is before start_date' do
        result = described_class.call(
          user: user,
          start_date: '2024-01-31',
          end_date: '2024-01-01'
        )

        expect(result.success?).to be false
        expect(result.errors).to be_present
      end

      it 'does not enqueue job on failure' do
        expect {
          described_class.call(user: user, start_date: 'invalid', end_date: 'invalid')
        }.not_to have_enqueued_job(Reports::GenerateJob)
      end
    end
  end

  describe '#call' do
    it 'can be called as instance method' do
      service = described_class.new(user: user, start_date: start_date, end_date: end_date)
      result = service.call

      expect(result.success?).to be true
    end
  end
end
