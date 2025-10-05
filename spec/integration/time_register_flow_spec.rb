require 'rails_helper'

RSpec.describe 'Complete Time Register Flow', type: :request do
  let!(:user) { create(:user, name: 'John Doe', email: 'john@example.com') }

  describe 'User creates and manages time registers' do
    it 'allows complete CRUD operations on time registers' do
      # Create a time register (clock in)
      post '/api/v1/time_registers', params: {
        time_register: {
          user_id: user.id,
          clock_in: Time.current
        }
      }

      expect(response).to have_http_status(:created)
      clocking_id = JSON.parse(response.body)['id']

      # List all time registers
      get '/api/v1/time_registers'
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)

      # Get specific time register
      get "/api/v1/time_registers/#{clocking_id}"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(clocking_id)

      # Update time register (clock out)
      clock_out_time = Time.current + 8.hours
      put "/api/v1/time_registers/#{clocking_id}", params: {
        time_register: { clock_out: clock_out_time }
      }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['clock_out']).to be_present

      # List user's time registers
      get "/api/v1/users/#{user.id}/time_registers"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)

      # Delete time register
      delete "/api/v1/time_registers/#{clocking_id}"
      expect(response).to have_http_status(:no_content)

      # Verify deletion
      get '/api/v1/time_registers'
      expect(JSON.parse(response.body)).to be_empty
    end
  end

  describe 'Business rules enforcement' do
    it 'prevents user from having multiple open clockings' do
      # Create first open clocking
      post '/api/v1/time_registers', params: {
        time_register: {
          user_id: user.id,
          clock_in: Time.current
        }
      }
      expect(response).to have_http_status(:created)

      # Try to create second open clocking
      post '/api/v1/time_registers', params: {
        time_register: {
          user_id: user.id,
          clock_in: Time.current
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to include('User already has an open clocking')
    end

    it 'prevents clock_out before clock_in' do
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
  end
end
