require 'rails_helper'

RSpec.describe 'Complete Report Generation Flow', type: :request do
  let!(:user) { create(:user) }

  before do
    create(:clocking, :completed, user: user, clock_in: 5.days.ago, clock_out: 5.days.ago + 8.hours)
    create(:clocking, :completed, user: user, clock_in: 4.days.ago, clock_out: 4.days.ago + 7.hours)
    create(:clocking, :completed, user: user, clock_in: 3.days.ago, clock_out: 3.days.ago + 9.hours)
  end

  describe 'Full report generation workflow' do
    it 'completes entire report lifecycle' do
      # Step 1: Request report generation
      post "/api/v1/users/#{user.id}/reports", params: {
        start_date: 7.days.ago.to_date,
        end_date: Date.today
      }

      expect(response).to have_http_status(:accepted)
      json_response = JSON.parse(response.body)
      process_id = json_response['process_id']
      expect(json_response['status']).to eq('queued')

      # Step 2: Check initial status
      get "/api/v1/reports/#{process_id}/status"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['status']).to eq('queued')

      # Step 3: Process the job
      perform_enqueued_jobs

      # Step 4: Check completed status
      get "/api/v1/reports/#{process_id}/status"
      expect(response).to have_http_status(:ok)
      status_response = JSON.parse(response.body)
      expect(status_response['status']).to eq('completed')
      expect(status_response['progress']).to eq(100)

      # Step 5: Download the report
      get "/api/v1/reports/#{process_id}/download"
      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Type']).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.body).to be_present
    end
  end

  describe 'Report generation with invalid parameters' do
    it 'rejects invalid date range' do
      post "/api/v1/users/#{user.id}/reports", params: {
        start_date: Date.today,
        end_date: 7.days.ago.to_date
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include('errors')
    end

    it 'rejects invalid date format' do
      post "/api/v1/users/#{user.id}/reports", params: {
        start_date: 'invalid-date',
        end_date: 'invalid-date'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include('errors')
    end
  end

  describe 'Report download restrictions' do
    it 'prevents download of queued report' do
      report_process = create(:report_process, user: user, status: :queued)

      get "/api/v1/reports/#{report_process.process_id}/download"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('Report not ready')
    end

    it 'prevents download of processing report' do
      report_process = create(:report_process, :processing, user: user)

      get "/api/v1/reports/#{report_process.process_id}/download"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('Report not ready')
    end

    it 'prevents download of failed report' do
      report_process = create(:report_process, :failed, user: user)

      get "/api/v1/reports/#{report_process.process_id}/download"

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'prevents download when file is not attached' do
      report_process = create(:report_process, user: user, status: :completed)

      get "/api/v1/reports/#{report_process.process_id}/download"

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to match(/Report not ready/)
    end
  end

  describe 'Multiple concurrent reports' do
    it 'allows multiple report requests for same user' do
      # Request first report
      post "/api/v1/users/#{user.id}/reports", params: {
        start_date: 30.days.ago.to_date,
        end_date: 15.days.ago.to_date
      }
      expect(response).to have_http_status(:accepted)
      first_process_id = JSON.parse(response.body)['process_id']

      # Request second report
      post "/api/v1/users/#{user.id}/reports", params: {
        start_date: 14.days.ago.to_date,
        end_date: Date.today
      }
      expect(response).to have_http_status(:accepted)
      second_process_id = JSON.parse(response.body)['process_id']

      # Verify different process IDs
      expect(first_process_id).not_to eq(second_process_id)

      # Both reports should be accessible
      get "/api/v1/reports/#{first_process_id}/status"
      expect(response).to have_http_status(:ok)

      get "/api/v1/reports/#{second_process_id}/status"
      expect(response).to have_http_status(:ok)
    end
  end
end
