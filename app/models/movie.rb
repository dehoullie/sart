class Movie < ApplicationRecord
  has_many :favorites, dependent: :destroy
  has_many :users, through: :favorites

  has_many :movies_genres, dependent: :destroy
  has_many :genres, through: :movies_genres

  has_many :characters, dependent: :destroy
  has_many :casts, through: :characters

  has_one_attached :poster
end
