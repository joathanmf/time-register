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
