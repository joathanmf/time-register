require 'rails_helper'

RSpec.describe "Api::V1::Reports", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/reports/:process_id/status" do
    context 'when report process exists' do
      let(:report_process) { create(:report_process, user: user) }

      it 'returns the report status' do
        get "/api/v1/reports/#{report_process.process_id}/status"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['process_id']).to eq(report_process.process_id)
        expect(json_response['status']).to eq('queued')
        expect(json_response['progress']).to eq(0)
      end

      it 'returns correct status for processing report' do
        report_process = create(:report_process, :processing, user: user)

        get "/api/v1/reports/#{report_process.process_id}/status"

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('processing')
        expect(json_response['progress']).to eq(50)
      end

      it 'returns correct status for completed report' do
        report_process = create(:report_process, :completed, user: user)

        get "/api/v1/reports/#{report_process.process_id}/status"

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('completed')
        expect(json_response['progress']).to eq(100)
      end

      it 'returns correct status for failed report' do
        report_process = create(:report_process, :failed, user: user)

        get "/api/v1/reports/#{report_process.process_id}/status"

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('failed')
      end
    end

    context 'when report process does not exist' do
      it 'returns not found status' do
        get '/api/v1/reports/non-existent-id/status'

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Report not found')
      end
    end
  end

  describe "GET /api/v1/reports/:process_id/download" do
    context 'when report is ready' do
      let(:report_process) { create(:report_process, :completed, user: user) }

      it 'returns the file' do
        get "/api/v1/reports/#{report_process.process_id}/download"

        expect(response).to have_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.headers['Content-Disposition']).to include("report_#{report_process.process_id}.csv")
      end

      it 'returns file content' do
        get "/api/v1/reports/#{report_process.process_id}/download"

        expect(response.body).to be_present
      end
    end

    context 'when report is not ready' do
      it 'returns error for queued report' do
        report_process = create(:report_process, user: user, status: :queued)

        get "/api/v1/reports/#{report_process.process_id}/download"

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Report not ready')
      end

      it 'returns error for processing report' do
        report_process = create(:report_process, :processing, user: user)

        get "/api/v1/reports/#{report_process.process_id}/download"

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Report not ready')
      end

      it 'returns error for failed report' do
        report_process = create(:report_process, :failed, user: user)

        get "/api/v1/reports/#{report_process.process_id}/download"

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error when file is not attached' do
        report_process = create(:report_process, user: user, status: :completed)

        get "/api/v1/reports/#{report_process.process_id}/download"

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to match(/Report not ready/)
      end
    end

    context 'when report process does not exist' do
      it 'returns not found status' do
        get '/api/v1/reports/non-existent-id/download'

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Report not found')
      end
    end
  end
end
