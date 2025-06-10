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

  def perform(api_movie_id, query = nil)
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

    # Enqueue cast/crew job
    SaveCastJob.perform_later(api_movie_id)

    # Enqueue images job
    SaveMovieImagesJob.perform_later(api_movie_id)

    # Turbo Stream broadcast for live search results
    if query.present?
      movie.broadcast_append_to(
        "search_results_#{query.parameterize}",
        target: "results_list",
        partial: "shared/movie_card",
        locals: { movie: movie }
      )
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
