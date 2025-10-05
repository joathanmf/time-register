require 'rails_helper'

RSpec.describe Reports::Calculators::WorkTimeCalculator, type: :service do
  subject { described_class.new }

  describe '#hours_worked' do
    context 'with completed clocking' do
      let(:clocking) { build(:clocking, clock_in: Time.current, clock_out: Time.current + 8.hours) }

      it 'returns formatted hours worked' do
        result = subject.hours_worked(clocking)

        expect(result).to eq('8h 0min')
      end
    end

    context 'with partial hours' do
      let(:clocking) { build(:clocking, clock_in: Time.current, clock_out: Time.current + 8.hours + 30.minutes) }

      it 'returns formatted hours and minutes' do
        result = subject.hours_worked(clocking)

        expect(result).to eq('8h 30min')
      end
    end

    context 'with open clocking' do
      let(:clocking) { build(:clocking, clock_in: Time.current, clock_out: nil) }

      it 'returns dash' do
        result = subject.hours_worked(clocking)

        expect(result).to eq('-')
      end
    end
  end

  describe '#total_hours' do
    context 'with multiple clockings' do
      let(:clockings) do
        [
          build(:clocking, clock_in: Time.current, clock_out: Time.current + 8.hours),
          build(:clocking, clock_in: Time.current, clock_out: Time.current + 7.hours + 30.minutes),
          build(:clocking, clock_in: Time.current, clock_out: Time.current + 9.hours)
        ]
      end

      it 'returns sum of all hours' do
        result = subject.total_hours(clockings)

        expect(result).to eq('24h 30min')
      end
    end

    context 'with open clockings' do
      let(:clockings) do
        [
          build(:clocking, clock_in: Time.current, clock_out: Time.current + 8.hours),
          build(:clocking, :open, clock_in: Time.current)
        ]
      end

      it 'excludes open clockings from total' do
        result = subject.total_hours(clockings)

        expect(result).to eq('8h 0min')
      end
    end

    context 'with empty array' do
      it 'returns dash for zero hours' do
        result = subject.total_hours([])

        expect(result).to eq('-')
      end
    end
  end

  describe '#seconds_worked' do
    context 'with completed clocking' do
      let(:clocking) { build(:clocking, clock_in: Time.current, clock_out: Time.current + 1.hour) }

      it 'returns seconds worked' do
        result = subject.seconds_worked(clocking)

        expect(result).to eq(3600)
      end
    end

    context 'with open clocking' do
      let(:clocking) { build(:clocking, clock_in: Time.current, clock_out: nil) }

      it 'returns 0' do
        result = subject.seconds_worked(clocking)

        expect(result).to eq(0)
      end
    end
  end
end
