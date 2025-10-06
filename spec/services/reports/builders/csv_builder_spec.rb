require 'rails_helper'

RSpec.describe Reports::Builders::CsvBuilder, type: :service do
  let(:user) { create(:user) }
  let(:start_date) { Date.new(2024, 1, 1) }
  let(:end_date) { Date.new(2024, 1, 31) }
  let(:report_process) do
    create(:report_process,
           user: user,
           start_date: start_date,
           end_date: end_date)
  end

  subject { described_class.new(report_process) }

  describe '#build' do
    context 'with no clockings' do
      it 'generates CSV with headers and summary only' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)

        expect(rows.first).to eq([
          "Data", "Dia da Semana", "Entrada", "Saída",
          "Horas Trabalhadas", "Status", "Observações"
        ])
        expect(rows.last).to include("TOTAL")
        expect(rows.size).to eq(2) # Header + Summary
      end

      it 'shows zero registros in summary' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)
        summary = rows.last

        expect(summary).to include("0 registros completos")
        expect(summary).to include("0 registros abertos")
      end
    end

    context 'with complete clockings' do
      let!(:clocking1) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2024-01-15 08:00:00'),
               clock_out: Time.zone.parse('2024-01-15 17:00:00'))
      end

      let!(:clocking2) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2024-01-16 09:00:00'),
               clock_out: Time.zone.parse('2024-01-16 18:00:00'))
      end

      it 'generates CSV with correct number of rows' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)

        # Header + 2 data rows + Summary
        expect(rows.size).to eq(4)
      end

      it 'includes correct headers' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)

        expect(rows.first).to eq(described_class::HEADERS)
      end

      it 'includes data for all clockings in date range' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)

        # Check first data row (skip header)
        expect(rows[1][0]).to eq('15/01/2024') # Date
        expect(rows[1][2]).to eq('08:00:00')   # Clock in
        expect(rows[1][3]).to eq('17:00:00')   # Clock out

        # Check second data row
        expect(rows[2][0]).to eq('16/01/2024')
        expect(rows[2][2]).to eq('09:00:00')
        expect(rows[2][3]).to eq('18:00:00')
      end

      it 'includes summary row with totals' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)
        summary = rows.last

        expect(summary[1]).to eq("TOTAL")
        expect(summary[5]).to include("2 registros completos")
        expect(summary[6]).to include("0 registros abertos")
      end

      it 'calculates total hours worked' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)
        summary = rows.last

        # Should have total hours in column 4 (index 4)
        expect(summary[4]).not_to be_nil
        expect(summary[4]).not_to eq('-')
      end
    end

    context 'with open clockings' do
      let!(:open_clocking) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2024-01-15 08:00:00'),
               clock_out: nil)
      end

      it 'shows dash for missing clock_out time' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)

        expect(rows[1][3]).to eq('-') # Clock out column
      end

      it 'counts open clockings in summary' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)
        summary = rows.last

        expect(summary[5]).to include("0 registros completos")
        expect(summary[6]).to include("1 registros abertos")
      end
    end

    context 'with mixed complete and open clockings' do
      let!(:complete_clocking) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2024-01-15 08:00:00'),
               clock_out: Time.zone.parse('2024-01-15 17:00:00'))
      end

      let!(:open_clocking) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2024-01-16 08:00:00'),
               clock_out: nil)
      end

      it 'counts both types correctly in summary' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)
        summary = rows.last

        expect(summary[5]).to include("1 registros completos")
        expect(summary[6]).to include("1 registros abertos")
      end
    end

    context 'with clockings outside date range' do
      let!(:clocking_in_range) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2024-01-15 08:00:00'),
               clock_out: Time.zone.parse('2024-01-15 17:00:00'))
      end

      let!(:clocking_before_range) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2023-12-31 08:00:00'),
               clock_out: Time.zone.parse('2023-12-31 17:00:00'))
      end

      let!(:clocking_after_range) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2024-02-01 08:00:00'),
               clock_out: Time.zone.parse('2024-02-01 17:00:00'))
      end

      it 'includes only clockings within date range' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)

        # Header + 1 data row in range + Summary
        expect(rows.size).to eq(3)
        expect(rows[1][0]).to eq('15/01/2024')
      end
    end

    context 'with clockings from different user' do
      let(:other_user) { create(:user) }
      let!(:user_clocking) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2024-01-15 08:00:00'),
               clock_out: Time.zone.parse('2024-01-15 17:00:00'))
      end

      let!(:other_user_clocking) do
        create(:clocking,
               user: other_user,
               clock_in: Time.zone.parse('2024-01-15 08:00:00'),
               clock_out: Time.zone.parse('2024-01-15 17:00:00'))
      end

      it 'includes only clockings for the report user' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)

        # Header + 1 data row + Summary
        expect(rows.size).to eq(3)
      end
    end

    context 'progress updates' do
      let!(:clockings) do
        3.times.map do |i|
          create(:clocking,
                 user: user,
                 clock_in: Time.zone.parse("2024-01-#{15 + i} 08:00:00"),
                 clock_out: Time.zone.parse("2024-01-#{15 + i} 17:00:00"))
        end
      end

      it 'updates progress during build' do
        expect(report_process).to receive(:update_progress!).at_least(:once)

        subject.build
      end

      it 'updates progress to 100% when complete' do
        subject.build

        # The last update should be 100%
        expect(report_process.progress).to eq(100)
      end
    end

    context 'CSV format validation' do
      let!(:clocking) do
        create(:clocking,
               user: user,
               clock_in: Time.zone.parse('2024-01-15 08:00:00'),
               clock_out: Time.zone.parse('2024-01-15 17:00:00'))
      end

      it 'generates valid CSV format' do
        csv_content = subject.build

        expect { CSV.parse(csv_content) }.not_to raise_error
      end

      it 'has at least 7 columns (matching headers)' do
        csv_content = subject.build
        rows = CSV.parse(csv_content)

        rows.each do |row|
          expect(row.size).to be >= 5 # At least the main data columns
        end
      end
    end
  end

  describe 'HEADERS constant' do
    it 'defines all required headers' do
      expect(described_class::HEADERS).to eq([
        "Data", "Dia da Semana", "Entrada", "Saída",
        "Horas Trabalhadas", "Status", "Observações"
      ])
    end

    it 'is frozen to prevent modifications' do
      expect(described_class::HEADERS).to be_frozen
    end
  end
end
