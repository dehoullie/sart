class CastsController < ApplicationController
  def index
    @movie = Movie.last
    @cast = @movie.casts
  end

  def show
  end
end
