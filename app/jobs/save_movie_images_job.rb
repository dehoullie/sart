class SaveMovieImagesJob < ApplicationJob
  queue_as :default

  API_TOKEN = ENV['TMDB_API_KEY']
  BASE_URL  = 'https://api.themoviedb.org/3'

  def perform(api_movie_id)
    movie = Movie.find_by(api_movie_id: api_movie_id)
    return unless movie

    details = fetch_json("/movie/#{api_movie_id}?language=en-US")

    # Poster image
    if details['poster_path'].present? && !movie.poster.attached?
      movie.poster.attach(
        io: URI.open("https://image.tmdb.org/t/p/w185#{details['poster_path']}"),
        filename: "#{api_movie_id}_poster_w185.jpg",
        content_type: 'image/jpeg',
        key: "sart/movies/#{api_movie_id}_poster"
      )
    end

    # Backdrop image
    if details['backdrop_path'].present? && !movie.backdrop.attached?
      movie.backdrop.attach(
        io: URI.open("https://image.tmdb.org/t/p/w780#{details['backdrop_path']}"),
        filename: "#{api_movie_id}_backdrop_w780.jpg",
        content_type: 'image/jpeg',
        key: "sart/movies/#{api_movie_id}_backdrop"
      )
    end
  end

  private

  def fetch_json(endpoint)
    uri  = URI("#{BASE_URL}#{endpoint}")
    http = Net::HTTP.new(uri.host, uri.port).tap { |h| h.use_ssl = true }
    req  = Net::HTTP::Get.new(uri)
    req['accept']        = 'application/json'
    req['Authorization'] = "Bearer #{API_TOKEN}"
    JSON.parse(http.request(req).body)
  end
end
