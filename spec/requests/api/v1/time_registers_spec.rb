require 'rails_helper'

RSpec.describe "Api::V1::TimeRegisters", type: :request do
  let(:user) { create(:user) }
  let(:clocking) { create(:clocking, user: user) }
  let(:valid_attributes) { { user_id: user.id, clock_in: Time.current } }
  let(:invalid_attributes) { { user_id: nil, clock_in: nil } }

  describe "GET /api/v1/time_registers" do
    context 'when time registers exist' do
      before do
        # Create clockings with different times to avoid validation
        create(:clocking, user: user, clock_in: 5.days.ago, clock_out: 5.days.ago + 8.hours)
        create(:clocking, user: user, clock_in: 4.days.ago, clock_out: 4.days.ago + 8.hours)
        create(:clocking, user: user, clock_in: 3.days.ago, clock_out: 3.days.ago + 8.hours)
        create(:clocking, user: user, clock_in: 2.days.ago, clock_out: 2.days.ago + 8.hours)
        create(:clocking, user: user, clock_in: 1.day.ago, clock_out: 1.day.ago + 8.hours)
      end

      it 'returns all time registers' do
        get '/api/v1/time_registers'

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(5)
      end

      it 'returns time registers with correct attributes' do
        get '/api/v1/time_registers'

        json_response = JSON.parse(response.body)
        expect(json_response.first).to include('id', 'user_id', 'clock_in', 'created_at', 'updated_at')
      end
    end

    context 'when no time registers exist' do
      it 'returns empty array' do
        get '/api/v1/time_registers'

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe "GET /api/v1/time_registers/:id" do
    context 'when time register exists' do
      it 'returns the time register' do
        get "/api/v1/time_registers/#{clocking.id}"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(clocking.id)
        expect(json_response['user_id']).to eq(user.id)
      end
    end

    context 'when time register does not exist' do
      it 'returns not found status' do
        get '/api/v1/time_registers/999999'

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Time register not found')
      end
    end
  end

  describe "POST /api/v1/time_registers" do
    context 'with valid parameters' do
      it 'creates a new time register' do
        expect {
          post '/api/v1/time_registers', params: { time_register: valid_attributes }
        }.to change(Clocking, :count).by(1)
      end

      it 'returns created status' do
        post '/api/v1/time_registers', params: { time_register: valid_attributes }

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['user_id']).to eq(user.id)
        expect(json_response['clock_in']).to be_present
      end

      it 'creates time register with clock_out' do
        clock_in_time = Time.current
        clock_out_time = clock_in_time + 8.hours

        post '/api/v1/time_registers', params: {
          time_register: {
            user_id: user.id,
            clock_in: clock_in_time,
            clock_out: clock_out_time
          }
        }

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['clock_out']).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new time register' do
        expect {
          post '/api/v1/time_registers', params: { time_register: invalid_attributes }
        }.not_to change(Clocking, :count)
      end

      it 'returns unprocessable entity status' do
        post '/api/v1/time_registers', params: { time_register: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end

      it 'validates clock_in presence' do
        post '/api/v1/time_registers', params: { time_register: { user_id: user.id } }

        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include(match(/Clock in can't be blank/))
      end
    end

    context 'with business rule validations' do
      it 'prevents creating second open clocking for same user' do
        create(:clocking, user: user, clock_out: nil)

        post '/api/v1/time_registers', params: {
          time_register: { user_id: user.id, clock_in: Time.current }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('User already has an open clocking')
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
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Clock out must be after clock in time')
      end
    end
  end

  describe "PUT /api/v1/time_registers/:id" do
    let(:clocking) { create(:clocking, user: user, clock_out: nil) }

    context 'with valid parameters' do
      it 'updates the time register' do
        clock_out_time = clocking.clock_in + 8.hours

        put "/api/v1/time_registers/#{clocking.id}",
            params: { time_register: { clock_out: clock_out_time } }

        clocking.reload
        expect(clocking.clock_out).to be_present
      end

      it 'returns success status' do
        put "/api/v1/time_registers/#{clocking.id}",
            params: { time_register: { clock_out: clocking.clock_in + 8.hours } }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['clock_out']).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'does not update with invalid clock_out' do
        put "/api/v1/time_registers/#{clocking.id}",
            params: { time_register: { clock_out: clocking.clock_in - 1.hour } }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Clock out must be after clock in time')
      end

      it 'does not update the record on failure' do
        original_clock_out = clocking.clock_out

        put "/api/v1/time_registers/#{clocking.id}",
            params: { time_register: { clock_out: clocking.clock_in - 1.hour } }

        clocking.reload
        expect(clocking.clock_out).to eq(original_clock_out)
      end
    end

    context 'when time register does not exist' do
      it 'returns not found status' do
        put '/api/v1/time_registers/999999',
            params: { time_register: { clock_out: Time.current } }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/time_registers/:id" do
    context 'when time register exists' do
      let!(:clocking_to_delete) { create(:clocking, user: user) }

      it 'deletes the time register' do
        expect {
          delete "/api/v1/time_registers/#{clocking_to_delete.id}"
        }.to change(Clocking, :count).by(-1)
      end

      it 'returns no content status' do
        delete "/api/v1/time_registers/#{clocking_to_delete.id}"

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when time register does not exist' do
      it 'returns not found status' do
        delete '/api/v1/time_registers/999999'

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
