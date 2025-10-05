require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  let(:user) { create(:user) }
  let(:valid_attributes) { { name: 'John Doe', email: 'john@example.com' } }
  let(:invalid_attributes) { { name: '', email: 'invalid-email' } }

  describe "GET /api/v1/users" do
    context 'when users exist' do
      let!(:users) { create_list(:user, 3) }

      it 'returns all users' do
        get '/api/v1/users'

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(3)
      end

      it 'returns users with correct attributes' do
        get '/api/v1/users'

        json_response = JSON.parse(response.body)
        expect(json_response.first).to include('id', 'name', 'email', 'created_at', 'updated_at')
      end
    end

    context 'when no users exist' do
      it 'returns empty array' do
        get '/api/v1/users'

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe "GET /api/v1/users/:id" do
    context 'when user exists' do
      it 'returns the user' do
        get "/api/v1/users/#{user.id}"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(user.id)
        expect(json_response['name']).to eq(user.name)
        expect(json_response['email']).to eq(user.email)
      end
    end

    context 'when user does not exist' do
      it 'returns not found status' do
        get '/api/v1/users/999999'

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'User not found')
      end
    end
  end

  describe "POST /api/v1/users" do
    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/users', params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'returns created status' do
        post '/api/v1/users', params: { user: valid_attributes }

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq('John Doe')
        expect(json_response['email']).to eq('john@example.com')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new user' do
        expect {
          post '/api/v1/users', params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end

      it 'returns unprocessable entity status' do
        post '/api/v1/users', params: { user: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end

      it 'returns validation errors' do
        post '/api/v1/users', params: { user: { name: '', email: '' } }

        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include(match(/Name can't be blank/))
        expect(json_response['errors']).to include(match(/Email can't be blank/))
      end
    end

    context 'with duplicate email' do
      it 'returns validation error' do
        create(:user, email: 'duplicate@example.com')
        post '/api/v1/users', params: { user: { name: 'Test', email: 'duplicate@example.com' } }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include(match(/Email has already been taken/))
      end
    end
  end

  describe "PUT /api/v1/users/:id" do
    context 'with valid parameters' do
      let(:new_attributes) { { name: 'Jane Doe', email: 'jane@example.com' } }

      it 'updates the user' do
        put "/api/v1/users/#{user.id}", params: { user: new_attributes }

        user.reload
        expect(user.name).to eq('Jane Doe')
        expect(user.email).to eq('jane@example.com')
      end

      it 'returns success status' do
        put "/api/v1/users/#{user.id}", params: { user: new_attributes }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq('Jane Doe')
      end
    end

    context 'with invalid parameters' do
      it 'does not update the user' do
        original_name = user.name
        put "/api/v1/users/#{user.id}", params: { user: invalid_attributes }

        user.reload
        expect(user.name).to eq(original_name)
      end

      it 'returns unprocessable entity status' do
        put "/api/v1/users/#{user.id}", params: { user: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end
    end

    context 'when user does not exist' do
      it 'returns not found status' do
        put '/api/v1/users/999999', params: { user: valid_attributes }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/users/:id" do
    context 'when user exists' do
      let!(:user_to_delete) { create(:user) }

      it 'deletes the user' do
        expect {
          delete "/api/v1/users/#{user_to_delete.id}"
        }.to change(User, :count).by(-1)
      end

      it 'returns no content status' do
        delete "/api/v1/users/#{user_to_delete.id}"

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when user does not exist' do
      it 'returns not found status' do
        delete '/api/v1/users/999999'

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v1/users/:id/time_registers" do
    context 'when user has clockings' do
      before do
        create(:clocking, user: user, clock_in: 3.days.ago, clock_out: 3.days.ago + 8.hours)
        create(:clocking, user: user, clock_in: 2.days.ago, clock_out: 2.days.ago + 8.hours)
        create(:clocking, user: user, clock_in: 1.day.ago, clock_out: 1.day.ago + 8.hours)
      end

      it 'returns all user clockings' do
        get "/api/v1/users/#{user.id}/time_registers"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(3)
      end

      it 'returns only clockings for the specified user' do
        other_user = create(:user)
        create(:clocking, user: other_user)

        get "/api/v1/users/#{user.id}/time_registers"

        expect(JSON.parse(response.body).size).to eq(3)
      end
    end

    context 'when user has no clockings' do
      it 'returns empty array' do
        get "/api/v1/users/#{user.id}/time_registers"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context 'when user does not exist' do
      it 'returns not found status' do
        get '/api/v1/users/999999/time_registers'

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/users/:id/reports" do
    context 'with valid parameters' do
      let(:report_params) { { start_date: '2024-01-01', end_date: '2024-01-31' } }

      it 'creates a report process' do
        expect {
          post "/api/v1/users/#{user.id}/reports", params: report_params
        }.to change(ReportProcess, :count).by(1)
      end

      it 'returns accepted status' do
        post "/api/v1/users/#{user.id}/reports", params: report_params

        expect(response).to have_http_status(:accepted)
        json_response = JSON.parse(response.body)
        expect(json_response).to include('process_id', 'status')
        expect(json_response['status']).to eq('queued')
      end

      it 'enqueues a job' do
        expect {
          post "/api/v1/users/#{user.id}/reports", params: report_params
        }.to have_enqueued_job(Reports::GenerateJob)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity with invalid dates' do
        post "/api/v1/users/#{user.id}/reports", params: { start_date: 'invalid', end_date: 'invalid' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end

      it 'returns error when end_date is before start_date' do
        post "/api/v1/users/#{user.id}/reports", params: { start_date: '2024-01-31', end_date: '2024-01-01' }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when user does not exist' do
      it 'returns not found status' do
        post '/api/v1/users/999999/reports', params: { start_date: '2024-01-01', end_date: '2024-01-31' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
