require 'rails_helper'

RSpec.describe Reports::Formatters::DateTimeFormatter, type: :service do
  subject { described_class.new }

  describe '#date' do
    it 'formats datetime to Brazilian date format' do
      datetime = Time.zone.parse('2024-01-15 10:30:00')

      expect(subject.date(datetime)).to eq('15/01/2024')
    end

    it 'returns dash for nil datetime' do
      expect(subject.date(nil)).to eq('-')
    end

    it 'returns dash for blank datetime' do
      expect(subject.date('')).to eq('-')
    end
  end

  describe '#weekday' do
    it 'returns weekday name' do
      datetime = Time.zone.parse('2024-01-15 10:30:00') # Monday

      result = subject.weekday(datetime)

      expect(result).to be_a(String)
      expect(result).not_to eq('-')
    end

    it 'returns dash for nil datetime' do
      expect(subject.weekday(nil)).to eq('-')
    end

    it 'handles I18n fallback gracefully' do
      datetime = Time.zone.parse('2024-01-15 10:30:00')

      expect { subject.weekday(datetime) }.not_to raise_error
    end
  end

  describe '#time' do
    it 'formats datetime to time with seconds' do
      datetime = Time.zone.parse('2024-01-15 10:30:45')

      expect(subject.time(datetime)).to eq('10:30:45')
    end

    it 'returns dash for nil datetime' do
      expect(subject.time(nil)).to eq('-')
    end

    it 'returns dash for blank datetime' do
      expect(subject.time('')).to eq('-')
    end
  end

  describe '#duration' do
    it 'formats hours and minutes' do
      seconds = 8 * 3600 + 30 * 60 # 8h 30min

      expect(subject.duration(seconds)).to eq('8h 30min')
    end

    it 'formats only hours when no minutes' do
      seconds = 5 * 3600 # 5h

      expect(subject.duration(seconds)).to eq('5h 0min')
    end

    it 'formats only minutes when less than hour' do
      seconds = 45 * 60 # 45min

      expect(subject.duration(seconds)).to eq('0h 45min')
    end

    it 'returns dash for zero seconds' do
      expect(subject.duration(0)).to eq('-')
    end
  end
end
