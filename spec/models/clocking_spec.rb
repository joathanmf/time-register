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
  pending "add some examples to (or delete) #{__FILE__}"
end
