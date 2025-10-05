# == Schema Information
#
# Table name: clockings
#
#  id         :bigint           not null, primary key
#  clock_in   :datetime         not null
#  clock_out  :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_clockings_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Clocking, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:clock_in) }

    context 'clock_out_after_clock_in validation' do
      let(:user) { create(:user) }

      it 'is valid when clock_out is after clock_in' do
        clocking = build(:clocking,
          user: user,
          clock_in: Time.current,
          clock_out: Time.current + 8.hours
        )

        expect(clocking).to be_valid
      end

      it 'is valid when clock_out is nil' do
        clocking = build(:clocking, user: user, clock_out: nil)

        expect(clocking).to be_valid
      end

      it 'is invalid when clock_out is before clock_in' do
        clocking = build(:clocking,
          user: user,
          clock_in: Time.current,
          clock_out: Time.current - 1.hour
        )

        expect(clocking).not_to be_valid
        expect(clocking.errors[:clock_out]).to include('must be after clock in time')
      end

      it 'is invalid when clock_out equals clock_in' do
        time = Time.current
        clocking = build(:clocking,
          user: user,
          clock_in: time,
          clock_out: time
        )

        expect(clocking).not_to be_valid
        expect(clocking.errors[:clock_out]).to include('must be after clock in time')
      end
    end

    context 'single_open_clocking validation' do
      let(:user) { create(:user) }

      it 'allows creating a clocking when user has no open clockings' do
        clocking = build(:clocking, user: user, clock_out: nil)

        expect(clocking).to be_valid
        expect(clocking.save).to be true
      end

      it 'prevents creating a second open clocking for the same user' do
        create(:clocking, user: user, clock_out: nil)
        second_clocking = build(:clocking, user: user, clock_out: nil)

        expect(second_clocking).not_to be_valid
        expect(second_clocking.errors[:base]).to include('User already has an open clocking')
      end

      it 'allows creating a new clocking after previous one is closed' do
        create(:clocking, user: user, clock_in: 1.day.ago, clock_out: 1.day.ago + 8.hours)
        new_clocking = build(:clocking, user: user, clock_out: nil)

        expect(new_clocking).to be_valid
        expect(new_clocking.save).to be true
      end

      it 'allows different users to have open clockings' do
        user1 = create(:user)
        user2 = create(:user)

        create(:clocking, user: user1, clock_out: nil)
        clocking2 = build(:clocking, user: user2, clock_out: nil)

        expect(clocking2).to be_valid
        expect(clocking2.save).to be true
      end

      it 'does not apply validation on update' do
        clocking = create(:clocking, user: user, clock_out: nil)

        clocking.clock_in = 1.hour.ago
        expect(clocking).to be_valid
        expect(clocking.save).to be true
      end
    end
  end

  describe 'creation' do
    let(:user) { create(:user) }

    context 'with valid attributes' do
      it 'creates a clocking successfully' do
        clocking = Clocking.new(
          user: user,
          clock_in: Time.current
        )

        expect(clocking.save).to be true
        expect(clocking).to be_persisted
      end
    end

    context 'with invalid attributes' do
      it 'fails without clock_in' do
        clocking = Clocking.new(user: user)

        expect(clocking.save).to be false
        expect(clocking.errors[:clock_in]).to include("can't be blank")
      end

      it 'fails without user' do
        clocking = Clocking.new(clock_in: Time.current)

        expect(clocking.save).to be false
        expect(clocking.errors[:user]).to be_present
      end
    end
  end

  describe 'update' do
    let(:user) { create(:user) }
    let(:clocking) { create(:clocking, user: user, clock_out: nil) }

    context 'with valid attributes' do
      it 'updates clock_out successfully' do
        new_clock_out = clocking.clock_in + 8.hours

        expect(clocking.update(clock_out: new_clock_out)).to be true
        expect(clocking.reload.clock_out).to eq(new_clock_out)
      end
    end

    context 'with invalid attributes' do
      it 'fails to update with invalid clock_out' do
        invalid_clock_out = clocking.clock_in - 1.hour

        expect(clocking.update(clock_out: invalid_clock_out)).to be false
        expect(clocking.errors[:clock_out]).to include('must be after clock in time')
      end
    end
  end
end
