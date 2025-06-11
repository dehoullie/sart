class GenresController < ApplicationController
  def index
    # Show all movies inside a genre, the genre should be passed as a parameter 'genre'
    @genres = Genre.all
    @genre = Genre.find_by(name: params[:genre]) if params[:genre]
    if @genre
      @movies = @genre.movies.includes(:genres).order(popularity: :desc).limit(20)
      render partial: "shared/results", locals: { movies: @movies }

    else
      @movies = Movie.none # No movies if genre not found
    end

  end
end
