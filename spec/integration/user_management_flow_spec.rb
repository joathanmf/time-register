require 'rails_helper'

RSpec.describe 'Complete User Management Flow', type: :request do
  describe 'User lifecycle' do
    it 'allows complete user management operations' do
      # Create user
      post '/api/v1/users', params: {
        user: {
          name: 'Alice Smith',
          email: 'alice@example.com'
        }
      }

      expect(response).to have_http_status(:created)
      user_id = JSON.parse(response.body)['id']

      # List all users
      get '/api/v1/users'
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)

      # Get specific user
      get "/api/v1/users/#{user_id}"
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['name']).to eq('Alice Smith')
      expect(json_response['email']).to eq('alice@example.com')

      # Update user
      put "/api/v1/users/#{user_id}", params: {
        user: {
          name: 'Alice Johnson',
          email: 'alice.j@example.com'
        }
      }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['name']).to eq('Alice Johnson')

      # Delete user
      delete "/api/v1/users/#{user_id}"
      expect(response).to have_http_status(:no_content)

      # Verify deletion
      get '/api/v1/users'
      expect(JSON.parse(response.body)).to be_empty
    end
  end

  describe 'User with associated data' do
    let!(:user) { create(:user) }

    it 'deletes user and associated clockings' do
      # Create clockings for user with different times to avoid validation
      create(:clocking, user: user, clock_in: 3.days.ago, clock_out: 3.days.ago + 8.hours)
      create(:clocking, user: user, clock_in: 2.days.ago, clock_out: 2.days.ago + 8.hours)
      create(:clocking, user: user, clock_in: 1.day.ago, clock_out: 1.day.ago + 8.hours)

      # Verify clockings exist
      get "/api/v1/users/#{user.id}/time_registers"
      expect(JSON.parse(response.body).size).to eq(3)

      # Delete user
      expect {
        delete "/api/v1/users/#{user.id}"
      }.to change(Clocking, :count).by(-3)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'Email uniqueness validation' do
    it 'enforces unique email constraint' do
      # Create first user
      post '/api/v1/users', params: {
        user: { name: 'User One', email: 'unique@example.com' }
      }
      expect(response).to have_http_status(:created)

      # Try to create second user with same email
      post '/api/v1/users', params: {
        user: { name: 'User Two', email: 'unique@example.com' }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to include(match(/Email has already been taken/))
    end
  end
end
