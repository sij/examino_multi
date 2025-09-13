class Owner < ApplicationRecord
  has_many :g1_details
  has_many :users

  validates :name, presence: true
  validates :gruppo, presence: true
end