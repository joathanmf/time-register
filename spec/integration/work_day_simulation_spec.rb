require 'rails_helper'

RSpec.describe 'Complete Work Day Simulation', type: :request do
  let!(:user) { create(:user, name: 'Worker', email: 'worker@example.com') }

  describe 'Typical work day flow' do
    it 'simulates a complete work day with clock in/out' do
      # Morning: Clock in
      morning_time = Time.current.change(hour: 9, min: 0)

      post '/api/v1/time_registers', params: {
        time_register: {
          user_id: user.id,
          clock_in: morning_time
        }
      }

      expect(response).to have_http_status(:created)
      clocking_id = JSON.parse(response.body)['id']

      # Verify clocking is open
      get "/api/v1/time_registers/#{clocking_id}"
      expect(JSON.parse(response.body)['clock_out']).to be_nil

      # Try to clock in again (should fail)
      post '/api/v1/time_registers', params: {
        time_register: {
          user_id: user.id,
          clock_in: Time.current
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)

      # Evening: Clock out
      evening_time = morning_time + 8.hours

      put "/api/v1/time_registers/#{clocking_id}", params: {
        time_register: { clock_out: evening_time }
      }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['clock_out']).to be_present

      # Verify can clock in again after clocking out
      post '/api/v1/time_registers', params: {
        time_register: {
          user_id: user.id,
          clock_in: evening_time + 1.day
        }
      }
      expect(response).to have_http_status(:created)
    end
  end

  describe 'Multiple days work tracking' do
    it 'tracks work for multiple days and generates report' do
      allow_any_instance_of(Reports::Builders::CsvBuilder).to receive(:sleep)

      # Create clockings for 5 days
      5.times do |day|
        clock_in = (5 - day).days.ago.change(hour: 9, min: 0)
        clock_out = clock_in + 8.hours

        post '/api/v1/time_registers', params: {
          time_register: {
            user_id: user.id,
            clock_in: clock_in,
            clock_out: clock_out
          }
        }
        expect(response).to have_http_status(:created)
      end

      # Verify all clockings are created
      get "/api/v1/users/#{user.id}/time_registers"
      expect(JSON.parse(response.body).size).to eq(5)

      # Request report for the period
      post "/api/v1/users/#{user.id}/reports", params: {
        start_date: 7.days.ago.to_date,
        end_date: Date.today
      }

      expect(response).to have_http_status(:accepted)
      process_id = JSON.parse(response.body)['process_id']

      # Process the report
      perform_enqueued_jobs

      # Download the report
      get "/api/v1/reports/#{process_id}/download"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Data') # CSV header
    end
  end

  describe 'Error handling scenarios' do
    it 'handles attempt to clock out before clock in' do
      clock_in_time = Time.current

      post '/api/v1/time_registers', params: {
        time_register: {
          user_id: user.id,
          clock_in: clock_in_time,
          clock_out: clock_in_time - 1.hour
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to include('Clock out must be after clock in time')
    end

    it 'handles non-existent user' do
      post '/api/v1/time_registers', params: {
        time_register: {
          user_id: 999999,
          clock_in: Time.current
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'handles non-existent time register' do
      get '/api/v1/time_registers/999999'

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to include('error' => 'Time register not found')
    end
  end
end
