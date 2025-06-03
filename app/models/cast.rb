class Cast < ApplicationRecord
  has_many :characters, dependent: :destroy
  has_many :movies, through: :characters
  validates :api_cast_id, uniqueness: true, allow_nil: true
end
