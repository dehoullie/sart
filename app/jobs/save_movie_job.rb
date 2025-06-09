# app/jobs/save_movie_job.rb
require 'uri'
require 'net/http'
require 'json'
require 'open-uri'
require 'date'

class SaveMovieJob < ApplicationJob
  queue_as :default

  API_TOKEN = ENV['TMDB_API_KEY']
  BASE_URL   = 'https://api.themoviedb.org/3'

  def perform(api_movie_id)
    if Movie.exists?(api_movie_id: api_movie_id)
      puts "SaveMovieJob: Movie with api_movie_id=#{api_movie_id} already exists"
      return
    end

    details = fetch_json("/movie/#{api_movie_id}?language=en-US")
    return unless details['title'].present?

    # Skip if not yet released
    if details['release_date'].blank? || Date.parse(details['release_date']) > Date.today
      puts "SaveMovieJob: Movie \"#{details['title']}\" not released until #{details['release_date']} — skipping"
      return
    end

    # Create or update Movie record
    movie = Movie.find_or_initialize_by(api_movie_id: details['id'])
    movie.assign_attributes(
      title:        details['title'],
      overview:     details['overview'],
      release_date: details['release_date'],
      runtime:      details['runtime'],
      popularity:   details['popularity']
    )
    movie.save!

    # Link Genres
    details['genres'].each do |g|
      genre = Genre.find_or_create_by!(api_genre_id: g['id']) { |gen| gen.name = g['name'] }
      MoviesGenre.find_or_create_by!(movie: movie, genre: genre)
    end

    # Fetch credits for cast & directors
    credits = fetch_json("/movie/#{api_movie_id}/credits")

    # Cast & Characters
    credits['cast'].first(10).each do |cast_data|
      cast = Cast.find_or_create_by!(api_cast_id: cast_data['id']) do |c|
        c.name = cast_data['name']
      end

      if cast_data['profile_path'].present?
        profile_id = "sart/cast/#{cast.api_cast_id}_profile"
        unless cloudinary_resource_exists?(profile_id)
          Cloudinary::Uploader.upload(
            "https://image.tmdb.org/t/p/original#{cast_data['profile_path']}",
            public_id: profile_id,
            overwrite:  false
          )
        end
        unless cast.photo.attached?
          url = Cloudinary::Utils.cloudinary_url(profile_id)
          cast.photo.attach(
            io:           URI.open(url),
            filename:     "#{cast.api_cast_id}_profile.jpg",
            content_type: 'image/jpeg'
          )
        end
      end

      Character.find_or_create_by!(movie: movie, cast: cast) do |ch|
        ch.character_name = cast_data['character']
      end
    end

    # Directors
    credits['crew'].select { |c| c['job'] == 'Director' }.each do |dir_data|
      director = Director.find_or_create_by!(api_cast_id: dir_data['id']) do |d|
        d.name = dir_data['name']
      end
      MovieDirector.find_or_create_by!(movie: movie, director: director)
    end

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

    cast_count     = movie.characters.count
    director_count = movie.directors.count
    puts "SaveMovieJob: Movie \"#{movie.title}\" (id=#{movie.api_movie_id}) inserted with #{cast_count} actors and #{director_count} directors"
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
