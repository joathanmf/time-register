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
FactoryBot.define do
  factory :clocking do
    association :user
    clock_in { Time.current }
    clock_out { clock_in + 8.hours }

    trait :open do
      clock_out { nil }
    end

    trait :completed do
      clock_out { clock_in + 8.hours }
    end

    trait :with_lunch_break do
      clock_in { Time.current.change(hour: 9) }
      clock_out { Time.current.change(hour: 18) }
    end
  end
end
