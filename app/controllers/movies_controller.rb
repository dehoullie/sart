class MoviesController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'cgi'
  TMDB_TOKEN = ENV.fetch("TMDB_API_KEY")

  def index
    q = params[:query].to_s.strip

    if q.present?
      # 1) search local DB
      local = Movie.where("title ILIKE ?", "%#{q}%").order(popularity: :desc).limit(5)

      # 2) if too few results, fetch top match from TMDb and save immediately
      if local.size < 3
        tmdb_url = URI("https://api.themoviedb.org/3/search/movie?query=#{CGI.escape(q)}&include_adult=false&language=en-US&page=1")
        http     = Net::HTTP.new(tmdb_url.host, tmdb_url.port)
        http.use_ssl = true
        req      = Net::HTTP::Get.new(tmdb_url)
        req["Authorization"] = "Bearer #{TMDB_TOKEN}"
        req["Accept"]        = "application/json"
        tmdb_res = http.request(req)
        results  = JSON.parse(tmdb_res.body)["results"] || []

        if results.any?
          # build list of existing TMDb IDs already in our local results
          existing_ids = local.map(&:api_movie_id)

          # sort TMDb results by descending popularity, extract their IDs
          candidates = results
            .sort_by { |r| -r["popularity"].to_f }
            .map    { |r| r["id"] }

          # determine how many more to enqueue
          needed = 3 - local.size

          # enqueue jobs for the top 'needed' movies not already in local
          candidates
            .reject { |id| existing_ids.include?(id) }
            .first(needed)
            .each { |movie_id| SaveMovieJob.perform_later(movie_id) }
        end

        # reload from DB after saving
        local = Movie.where("title ILIKE ?", "%#{q}%").order(popularity: :desc).limit(5)
      end

      @movies = local
      render partial: "shared/results"
    else
      # your existing “noq” branch unchanged
      @movies     = Movie.limit(3)
      @last_three = Movie.order(popularity: :desc).limit(3) if Movie.count > 3
      @top_genres = Genre.left_joins(:movies)
                        .group(:id)
                        .order("COUNT(movies.id) DESC")
                        .limit(5)
      @genres     = Genre.all
      @popular_movies = Movie.order(popularity: :desc).limit(5)
      respond_to { |format| format.html }
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
