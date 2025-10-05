# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:clockings).dependent(:destroy) }
    it { should have_many(:report_processes).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }

    context 'email format validation' do
      it 'accepts valid email formats' do
        valid_emails = [
          'user@example.com',
          'USER@foo.COM',
          'A_US-ER@foo.bar.org',
          'first.last@foo.jp',
          'alice+bob@baz.cn'
        ]

        valid_emails.each do |valid_email|
          user = build(:user, email: valid_email)
          expect(user).to be_valid, "#{valid_email} should be valid"
        end
      end

      it 'rejects invalid email formats' do
        invalid_emails = [
          'user@example,com',
          'user_at_foo.org',
          'user.name@example.',
          'foo@bar_baz.com',
          'foo@bar+baz.com',
          '@example.com',
          'user@',
          'user'
        ]

        invalid_emails.each do |invalid_email|
          user = build(:user, email: invalid_email)
          expect(user).not_to be_valid, "#{invalid_email} should be invalid"
        end
      end
    end
  end

  describe 'creation' do
    context 'with valid attributes' do
      it 'creates a user successfully' do
        user = User.new(name: 'John Doe', email: 'john@example.com')

        expect(user.save).to be true
        expect(user).to be_persisted
        expect(user.name).to eq('John Doe')
        expect(user.email).to eq('john@example.com')
      end
    end

    context 'with invalid attributes' do
      it 'fails without a name' do
        user = User.new(email: 'john@example.com')

        expect(user.save).to be false
        expect(user.errors[:name]).to include("can't be blank")
      end

      it 'fails without an email' do
        user = User.new(name: 'John Doe')

        expect(user.save).to be false
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'fails with duplicate email' do
        create(:user, email: 'john@example.com')
        user = build(:user, email: 'john@example.com')

        expect(user.save).to be false
        expect(user.errors[:email]).to include('has already been taken')
      end
    end
  end

  describe 'dependent destroy' do
    let(:user) { create(:user) }

    it 'destroys associated clockings when user is destroyed' do
      create(:clocking, user: user, clock_in: 3.days.ago, clock_out: 3.days.ago + 8.hours)
      create(:clocking, user: user, clock_in: 2.days.ago, clock_out: 2.days.ago + 8.hours)
      create(:clocking, user: user, clock_in: 1.day.ago, clock_out: 1.day.ago + 8.hours)

      expect { user.destroy }.to change { Clocking.count }.by(-3)
    end

    it 'destroys associated report_processes when user is destroyed' do
      create(:report_process, user: user, start_date: 7.days.ago, end_date: Date.today)
      create(:report_process, user: user, start_date: 14.days.ago, end_date: 7.days.ago)

      expect { user.destroy }.to change { ReportProcess.count }.by(-2)
    end
  end
end
