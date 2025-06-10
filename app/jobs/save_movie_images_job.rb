class SaveMovieImagesJob < ApplicationJob
  queue_as :default

  API_TOKEN = ENV['TMDB_API_KEY']
  BASE_URL  = 'https://api.themoviedb.org/3'

  def perform(api_movie_id)
    movie = Movie.find_by(api_movie_id: api_movie_id)
    return unless movie

    details = fetch_json("/movie/#{api_movie_id}?language=en-US")

    # Poster image
    if details['poster_path'].present?
      poster_id = "sart/movies/#{api_movie_id}_poster"
      unless cloudinary_resource_exists?(poster_id)
        Cloudinary::Uploader.upload(
          "https://image.tmdb.org/t/p/original#{details['poster_path']}",
          public_id: poster_id,
          overwrite:  false
        )
      end
      unless movie.poster.attached?
        url = Cloudinary::Utils.cloudinary_url(poster_id)
        movie.poster.attach(
          io:           URI.open(url),
          filename:     "#{api_movie_id}_poster.jpg",
          content_type: 'image/jpeg'
        )
      end
    end

    # Backdrop image
    if details['backdrop_path'].present?
      backdrop_id = "sart/movies/#{api_movie_id}_backdrop"
      unless cloudinary_resource_exists?(backdrop_id)
        Cloudinary::Uploader.upload(
          "https://image.tmdb.org/t/p/original#{details['backdrop_path']}",
          public_id: backdrop_id,
          overwrite:  false
        )
      end
      unless movie.backdrop.attached?
        url = Cloudinary::Utils.cloudinary_url(backdrop_id)
        movie.backdrop.attach(
          io:           URI.open(url),
          filename:     "#{api_movie_id}_backdrop.jpg",
          content_type: 'image/jpeg'
        )
      end
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
