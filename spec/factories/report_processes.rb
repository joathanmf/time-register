# == Schema Information
#
# Table name: report_processes
#
#  id            :bigint           not null, primary key
#  end_date      :date             not null
#  error_message :text
#  progress      :integer          default(0)
#  start_date    :date             not null
#  status        :string           default("queued"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  process_id    :string           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_report_processes_on_process_id  (process_id) UNIQUE
#  index_report_processes_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :report_process do
    association :user
    start_date { Date.today - 7.days }
    end_date { Date.today }
    status { :queued }
    progress { 0 }

    trait :processing do
      status { :processing }
      progress { 50 }
    end

    trait :completed do
      status { :completed }
      progress { 100 }

      after(:create) do |report_process|
        report_process.file.attach(
          io: StringIO.new('test,data\n1,2'),
          filename: "report_#{report_process.process_id}.csv",
          content_type: 'text/csv'
        )
      end
    end

    trait :failed do
      status { :failed }
      progress { 0 }
      error_message { 'Something went wrong' }
    end
  end
end
