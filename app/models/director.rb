# app/models/director.rb
class Director < ApplicationRecord
  has_many :movie_directors # This refers to the join model
  has_many :movies, through: :movie_directors
  has_one_attached :profile_picture
end
