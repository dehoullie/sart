class Genre < ApplicationRecord
  has_many :movies_genres, dependent: :destroy
  has_many :movies, through: :movies_genres
end
