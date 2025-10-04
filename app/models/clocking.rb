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
class Clocking < ApplicationRecord
  belongs_to :user

  validates :clock_in, presence: true

  # Clock_out deve ser posterior ao clock_in
  # Usuário não pode ter mais de um registro de ponto "aberto" (sem clock_out)
  validate :clock_out_after_clock_in
  validate :single_open_clocking, on: :create

  private

  def clock_out_after_clock_in
    return if clock_out.nil? || clock_in.nil?

    if clock_out < clock_in
      errors.add(:clock_out, "must be after clock in time")
    end
  end

  def single_open_clocking
    if Clocking.exists?(user_id: user_id, clock_out: nil)
      errors.add(:base, "User already has an open clocking")
    end
  end
end
