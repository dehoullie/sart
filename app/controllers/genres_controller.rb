class GenresController < ApplicationController
  def index
    @genres = Genre.all # Fetch all genres from the database
  end
end
