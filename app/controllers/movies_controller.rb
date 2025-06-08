class MoviesController < ApplicationController
  def index
    q = params[:query].to_s.strip if params[:query].present?

    if q.present?
      # User submitted a non‐empty search. Return just the search results partial.
      @movies = Movie
        .left_outer_joins(characters: :cast)
        .where(
          "movies.title ILIKE :q
           OR movies.overview ILIKE :q
           OR characters.character_name ILIKE :q
           OR casts.name ILIKE :q",
          q: "%#{q}%"
        )
        .distinct
        .order(popularity: :desc)
        .limit(10)
      render partial: "shared/results", locals: { movies: @movies }
    else
      # No search term: render the full index (banner + home-content) as normal
      @movies     = Movie.limit(3)                            # for banner & home-content
      @last_three = Movie.order(popularity: :desc).limit(3) if Movie.count > 3 # for banner
      # Get a list of 5 genres with most count movies
      @top_genres   = Genre
        .left_joins(:movies)
        .group(:id)
        .order("COUNT(movies.id) DESC")
        .limit(5)
      @genres       = Genre.all
      # Popular movies for the home-content section order by popularity column in the movies table
      @popular_movies = Movie.order(popularity: :desc).limit(5)

      respond_to do |format|
        format.html   # will render app/views/movies/index.html.erb
      end
    end
  end

  def show
    @movie = Movie.find(params[:id])
    @cast = @movie.casts.includes(:characters)
    @genres = @movie.genres
    @is_favorite = current_user.favorites.exists?(movie_id: @movie.id) if user_signed_in?
    # Similar movies list by genre / category

    # Now I'm gonna call the MovieProvidersFetcher service to get watch providers
    country = session[:country_code] || "us"

    result_hash       = MovieProvidersFetcher.new(
                          tmdb_id:      @movie.api_movie_id,
                          country_code: country
                        ).call

    if result_hash.values_at(:flatrate, :rent, :buy).all?(&:empty?)

      result_hash = MovieProvidersFetcher.new(
                      tmdb_id:      @movie.api_movie_id,
                      country_code: "us"
                    ).call
    end

    @providers = result_hash

    # Trying to get the links to the movies:
    # Attempt to get JustWatch deep-link offers
    # @watch_offers = JustwatchPartner.new(
    #   tmdb_id: @movie.api_movie_id,
    #   country: session[:country_code] || 'US'
    # ).offers_with_urls
    # SIMILAR MOVIES: find other movies that share at least one genre with current movie
    genre_ids = @genres.pluck(:id)
    @similar_movies = Movie
      .joins(:genres)
      .where(genres: { id: genre_ids })
      .where.not(id: @movie.id)
      .distinct
      .order(popularity: :desc)
      .limit(10)
  end
  # other actions (show, etc.) remain unchanged
end
