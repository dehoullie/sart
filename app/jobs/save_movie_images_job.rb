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
      poster_public_id = "sart/movies/#{api_movie_id}_poster"

      unless cloudinary_resource_exists?(poster_public_id)
        poster_url = "https://image.tmdb.org/t/p/original#{details['poster_path']}"
        Cloudinary::Uploader.upload(
          poster_url,
          public_id: poster_public_id,
          overwrite: false
        )
      end

      cloudinary_link = Cloudinary::Utils.cloudinary_url(poster_public_id)
      movie.poster.attach(
        io: URI.open(cloudinary_link),
        filename: "#{api_movie_id}_poster.jpg",
        content_type: 'image/jpeg'
      )
    end

    # Backdrop image
    if details['backdrop_path'].present? && !movie.backdrop.attached?
      backdrop_public_id = "sart/movies/#{api_movie_id}_backdrop"

      unless cloudinary_resource_exists?(backdrop_public_id)
        backdrop_url = "https://image.tmdb.org/t/p/original#{details['backdrop_path']}"
        Cloudinary::Uploader.upload(
          backdrop_url,
          public_id: backdrop_public_id,
          overwrite: false
        )
      end

      cloudinary_link = Cloudinary::Utils.cloudinary_url(backdrop_public_id)
      movie.backdrop.attach(
        io: URI.open(cloudinary_link),
        filename: "#{api_movie_id}_backdrop.jpg",
        content_type: 'image/jpeg'
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

  def cloudinary_resource_exists?(public_id)
    Cloudinary::Api.resource(public_id)
    true
  rescue Cloudinary::Api::NotFound
    false
  end
end
