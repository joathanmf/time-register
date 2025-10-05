require 'rails_helper'

RSpec.describe Reports::BaseReport, type: :service do
  let(:user) { create(:user) }
  let(:report_process) { create(:report_process, user: user) }

  # Concrete implementation for testing abstract class
  class TestReport < Reports::BaseReport
    def build_content
      "test,content\n1,2"
    end
  end

  describe '#generate' do
    subject { TestReport.new(report_process) }

    context 'successful generation' do
      it 'marks report as processing' do
        subject.generate

        expect(report_process.reload.status).to eq('processing').or eq('completed')
      end

      it 'attaches the file' do
        subject.generate

        expect(report_process.reload.file.attached?).to be true
      end

      it 'marks report as completed' do
        subject.generate

        expect(report_process.reload.status).to eq('completed')
      end

      it 'sets progress to 100' do
        subject.generate

        expect(report_process.reload.progress).to eq(100)
      end

      it 'clears error message' do
        report_process.update(error_message: 'Previous error')
        subject.generate

        expect(report_process.reload.error_message).to be_nil
      end
    end

    context 'failed generation' do
      before do
        allow(subject).to receive(:build_content).and_raise(StandardError.new('Generation failed'))
      end

      it 'marks report as failed' do
        expect { subject.generate }.to raise_error(StandardError)

        expect(report_process.reload.status).to eq('failed')
      end

      it 'stores error message' do
        expect { subject.generate }.to raise_error(StandardError)

        expect(report_process.reload.error_message).to eq('Generation failed')
      end

      it 'resets progress to 0' do
        report_process.update(progress: 50)

        expect { subject.generate }.to raise_error(StandardError)

        expect(report_process.reload.progress).to eq(0)
      end

      it 're-raises the error' do
        expect { subject.generate }.to raise_error(StandardError, 'Generation failed')
      end
    end
  end

  describe 'subclass implementation' do
    class IncompleteReport < Reports::BaseReport
      # Does not implement build_content
    end

    it 'raises NotImplementedError if build_content is not implemented' do
      incomplete_report = IncompleteReport.new(report_process)

      expect { incomplete_report.generate }.to raise_error(NotImplementedError)
    end
  end
end
