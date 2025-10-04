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
class User < ApplicationRecord
  has_many :clockings, dependent: :destroy
  has_many :report_processes, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  # Validações de formato de email
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
end
