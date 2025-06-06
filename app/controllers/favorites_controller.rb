class FavoritesController < ApplicationController
  # before_action :authenticate_user!

  def index
    if current_user
      @movies = current_user.favorite_movies
    end
  end

  def create
    movie = Movie.find(params[:id])
    favorite = Favorite.find_by(user: current_user, movie: movie)

    if favorite
      favorite.destroy
      favorited = false
    else
      Favorite.create(user: current_user, movie: movie)
      favorited = true
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: movie_path(movie) }
      format.json { render json: { favorited: favorited } }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "favorite_#{movie.id}",
          partial: "favorites/favorite",
          locals: { movie: movie }
        )
      end
    end
  end

  def destroy
  end
end
