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
require 'rails_helper'

RSpec.describe ReportProcess, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
