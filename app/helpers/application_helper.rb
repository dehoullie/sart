module ApplicationHelper
  def cloudinary_poster(movie)
    "https://res.cloudinary.com/dvhp2dk43/image/upload/sart/movies/#{movie.api_movie_id}_poster.jpg"
  end

  def cloudinary_backdrop(movie)
    "https://res.cloudinary.com/dvhp2dk43/image/upload/sart/movies/#{movie.api_movie_id}_backdrop"
  end

  def cloudinary_cast_photo(cast)
    "https://res.cloudinary.com/dvhp2dk43/image/upload/sart/cast/#{cast.api_cast_id}_profile"
  end

  # NEW: Returns the best poster URL (Cloudinary if attached, else TMDb live, else fallback)
  def movie_poster_url(movie)
    if movie.poster.attached?
      cloudinary_poster(movie)
    else
      poster_path = fetch_poster_path_from_api(movie.api_movie_id)
      if poster_path.present?
        "https://image.tmdb.org/t/p/original#{poster_path}"
      else
        asset_path("fallback-image.jpg")
      end
    end
  end

  # Helper to fetch poster_path from TMDb API live
  def fetch_poster_path_from_api(api_movie_id)
    api_token = ENV['TMDB_API_KEY']
    base_url  = 'https://api.themoviedb.org/3'
    uri = URI("#{base_url}/movie/#{api_movie_id}?language=en-US")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri)
    req['accept'] = 'application/json'
    req['Authorization'] = "Bearer #{api_token}"
    response = http.request(req)
    details = JSON.parse(response.body)
    details['poster_path']
  rescue
    nil
  end

  def cloudinary_poster_exists?(movie)
    require 'net/http'
    url = cloudinary_poster(movie)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    response.is_a?(Net::HTTPSuccess)
  rescue
    false
  end

  def best_movie_poster_url(movie)
    if cloudinary_poster_exists?(movie)
      cloudinary_poster(movie)
    else
      movie_poster_url(movie)
    end
  end

  def fetch_movie_id(query)
    api_token = ENV['TMDB_API_KEY']
    tmdb_url = URI("https://api.themoviedb.org/3/search/movie?query=#{CGI.escape(query)}&include_adult=false&language=en-US&page=1")
    http     = Net::HTTP.new(tmdb_url.host, tmdb_url.port)
    http.use_ssl = true
    req      = Net::HTTP::Get.new(tmdb_url)
    req["Authorization"] = "Bearer #{api_token}"
    req["Accept"]        = "application/json"
    tmdb_res = http.request(req)
    results  = JSON.parse(tmdb_res.body)["results"] || []

    first_result = results.first
    movie_id = first_result["id"]
    return movie_id
  end
end
