class MoviesController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'cgi'
  TMDB_TOKEN = ENV.fetch("TMDB_API_KEY")

  def index
    q = params[:query].to_s.strip
    @query = q

    if q.present?
      # 1) search local DB
      local = Movie.where("title ILIKE ?", "%#{q}%").order(popularity: :desc).limit(5)

      # 2) if too few results, fetch top match from TMDb and save immediately
      if local.size < 10
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
          needed = 10 - local.size

          # enqueue jobs for the top 'needed' movies not already in local
          candidates
            .reject { |id| existing_ids.include?(id) }
            .first(needed)
            .each { |movie_id| SaveMovieJob.perform_later(movie_id, q) }
        end

        # reload from DB after saving
        local = Movie.where("title ILIKE ?", "%#{q}%").order(popularity: :desc).limit(5)
      end

      @movies = local
      render partial: "shared/results"
    else

      @movies     = Movie.limit(3)
      @last_movies = Movie.order(popularity: :desc).limit(10) if Movie.count > 3
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
    cast_info = fetch_cast_info(@movie.api_movie_id)
    @director_name = cast_info[:director_name]
    @top_cast = cast_info[:cast]
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

    # SIMILAR MOVIES: find other movies that share at least one genre with current movie
    genre_ids = @genres.pluck(:id)
    @similar_movies = Movie
      .joins(:genres)
      .where(genres: { id: genre_ids })
      .where.not(id: @movie.id)
      .distinct
      .order(popularity: :desc)
      .limit(10)

    # === NEW: fetch TMDb videos ===
    uri = URI("https://api.themoviedb.org/3/movie/#{@movie.api_movie_id}/videos?language=en-US")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{TMDB_TOKEN}"
    req["Accept"]        = "application/json"
    resp = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    all_vids = JSON.parse(resp.body)["results"] || []

    # select only YouTube trailers, keep “official” first
    yt       = all_vids.select { |v| v["site"] == "YouTube" }
    trailers = yt.select { |v| v["type"] == "Trailer" && v["official"] }  # official trailers first
    others   = yt.reject { |v| trailers.include?(v) }                    # fallback clips
    @videos  = (trailers + others).first(3)                              # up to 3 videos

    # background banner clip: pick the first official Clip (or Trailer) if you like
    banner   = yt.find { |v| v["official"] && v["type"] == "Trailer" } ||
               yt.find { |v| v["official"] && v["type"] == "Clip" }
    @banner_key = banner && banner["key"]
  end

  private

  def fetch_director_name(api_movie_id)
    api_token = ENV['TMDB_API_KEY']
    base_url  = 'https://api.themoviedb.org/3'
    uri = URI("#{base_url}/movie/#{api_movie_id}/credits")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri)
    req['accept'] = 'application/json'
    req['Authorization'] = "Bearer #{api_token}"
    response = http.request(req)
    credits = JSON.parse(response.body)
    director = credits['crew']&.find { |c| c['job'] == 'Director' }
    director ? director['name'] : nil
  end

  def fetch_cast_info(api_movie_id)
    api_token = ENV['TMDB_API_KEY']
    base_url  = 'https://api.themoviedb.org/3'
    uri = URI("#{base_url}/movie/#{api_movie_id}/credits")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri)
    req['accept'] = 'application/json'
    req['Authorization'] = "Bearer #{api_token}"
    response = http.request(req)
    credits = JSON.parse(response.body)

    director = credits['crew']&.find { |c| c['job'] == 'Director' }
    director_name = director ? director['name'] : nil

    cast_array = credits['cast']&.first(10)&.map do |actor|
      {
        name: actor['name'],
        character: actor['character'],
        profile_path: actor['profile_path']
      }
    end || []

    { director_name: director_name, cast: cast_array }
  end
end
