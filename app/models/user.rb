class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :favorites, dependent: :destroy
  has_many :favorite_movies, through: :favorites, source: :movie

  # ActiveStorage
  has_one_attached :avatar

  # Virtual flag for removal
  attr_accessor :remove_avatar

  # If flagged, purge after save
  before_save :purge_avatar, if: -> { remove_avatar == '1' }

  private

  def purge_avatar
    avatar.purge_later
  end
end
