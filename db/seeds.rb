# db/seeds.rb

# =============================================================================
# Seed Script: Populate the database with TMDB data (genres, movies, cast, etc.)
# and upload each poster/backdrop/actor-photo to Cloudinary exactly once.
#
# Prerequisites:
# • ENV['TMDB_API_KEY'] must be set.
# • ENV['CLOUDINARY_URL'] must be set (so Cloudinary gem knows your credentials).
# • config/storage.yml includes a "cloudinary" service.
# • config/environments/development.rb (and/or production.rb) uses:
#     config.active_storage.service = :cloudinary
#
# Workflow:
# 1) Create (or find) all Genres.
# 2) Fetch top-rated movies → for each:
#    a) find_or_create Movie record,
#    b) link its Genres,
#    c) fetch first 10 cast → find_or_create Cast & Character, upload/attach actor-photo,
#    d) fetch Director(s) → find_or_create Director & MoviesDirector join,
#    e) upload poster/backdrop to Cloudinary (if missing) and attach locally.
# 3) Print summary counts.
# =============================================================================

require 'open-uri'     # for URI.open(...)
require 'net/http'
require 'uri'
require 'json'
require 'cloudinary'
require 'cloudinary/uploader'
require 'cloudinary/utils'

# If you placed the helper in lib/cloudinary_helper.rb, require it here:
# (Uncomment the next two lines if you created lib/cloudinary_helper.rb)
# require_relative '../lib/cloudinary_helper'
# include CloudinaryHelper

# Otherwise, define the helper inline:
def cloudinary_resource_exists?(public_id)
  begin
    Cloudinary::Api.resource(public_id)
    true
  rescue Cloudinary::Api::NotFound
    false
  end
end

# -----------------------------------------------------------------------------
# Helper: Fetch JSON from TMDB
API_TOKEN = ENV['TMDB_API_KEY']
BASE_URL   = "https://api.themoviedb.org/3"

def fetch_json(endpoint)
  url = URI("#{BASE_URL}#{endpoint}")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request["accept"]        = "application/json"
  request["Authorization"] = "Bearer #{API_TOKEN}"

  response = http.request(request)
  JSON.parse(response.body)
end

# -----------------------------------------------------------------------------
# 1) Seed Genres (find_or_create_by api_genre_id)
puts "🌱 Seeding genres..."
genre_data = fetch_json("/genre/movie/list?language=en")["genres"]

genre_data.each do |g|
  Genre.find_or_create_by!(api_genre_id: g["id"]) do |genre|
    genre.name = g["name"]
  end
end

puts "✅ Genres in DB: #{Genre.count}"

# -----------------------------------------------------------------------------
# 2) Fetch top-rated movies and process each one
puts "🎬 Seeding top-rated movies..."

movies_data = fetch_json("/movie/top_rated?language=en-US&page=1")["results"]

movies_data.each do |movie_data|
  details = fetch_json("/movie/#{movie_data['id']}?language=en-US")
  next unless details["title"].present?

  # 2a) Find or create Movie record
  movie = Movie.find_or_create_by(api_movie_id: details["id"]) do |m|
    m.title        = details["title"]
    m.overview     = details["overview"]
    m.release_date = details["release_date"]
    m.runtime      = details["runtime"]
    m.popularity   = details["popularity"]
  end

  # 2b) Link Genres (avoid duplicates)
  details["genres"].each do |genre_hash|
    genre = Genre.find_by(api_genre_id: genre_hash["id"])
    next unless genre
    MoviesGenre.find_or_create_by!(movie: movie, genre: genre)
  end

  # 2c) Fetch credits to handle Cast & Characters & Directors
  credits = fetch_json("/movie/#{movie.api_movie_id}/credits")

  # ----- CAST + CHARACTER (first 10) -----
  credits["cast"].first(10).each do |cast_data|
    cast = Cast.find_or_create_by(api_cast_id: cast_data["id"]) do |c|
      c.name = cast_data["name"]
    end

    # Only upload actor-photo if TMDB gave a profile_path
    if cast_data["profile_path"].present?
      profile_public_id = "sart/cast/#{cast.api_cast_id}_profile"

      if cloudinary_resource_exists?(profile_public_id)
        puts "📌 Actor photo already on Cloudinary for '#{cast.name}'. Skipping upload."
      else
        profile_url = "https://image.tmdb.org/t/p/original#{cast_data['profile_path']}"
        puts "⬆️  Uploading actor '#{cast.name}' photo to Cloudinary as #{profile_public_id}..."
        Cloudinary::Uploader.upload(
          profile_url,
          public_id: profile_public_id,
          overwrite: false
        )
        puts "✅ Uploaded actor '#{cast.name}' photo."
      end

      # Attach to ActiveStorage locally if not already attached
      unless cast.photo.attached?
        cloudinary_link = Cloudinary::Utils.cloudinary_url(profile_public_id)
        cast.photo.attach(
          io:           URI.open(cloudinary_link),
          filename:     "#{cast.api_cast_id}_profile.jpg",
          content_type: "image/jpeg"
        )
        puts "📌 Attached actor '#{cast.name}' photo to ActiveStorage."
      end
    end

    # Create Character join (movie <-> cast) if not already present
    Character.find_or_create_by!(movie: movie, cast: cast) do |ch|
      ch.character_name = cast_data["character"]
    end
  end

  # ----- DIRECTOR(S) -----
  credits["crew"].select { |c| c["job"] == "Director" }.each do |dir_data|
    director = Director.find_or_create_by(api_cast_id: dir_data["id"]) do |d|
      d.name = dir_data["name"]
    end

    MovieDirector.find_or_create_by!(movie: movie, director: director)
  end

  # ----- POSTER (Active Storage + Cloudinary) -----
  if details["poster_path"].present?
    poster_public_id = "sart/movies/#{movie.api_movie_id}_poster"

    if cloudinary_resource_exists?(poster_public_id)
      puts "📌 Poster already exists on Cloudinary for '#{movie.title}'."
    else
      poster_url = "https://image.tmdb.org/t/p/original#{details['poster_path']}"
      puts "⬆️  Uploading poster for '#{movie.title}' as #{poster_public_id}..."
      Cloudinary::Uploader.upload(
        poster_url,
        public_id: poster_public_id,
        overwrite: false
      )
      puts "✅ Uploaded poster for '#{movie.title}'."
    end

    unless movie.poster.attached?
      cloudinary_link = Cloudinary::Utils.cloudinary_url(poster_public_id)
      movie.poster.attach(
        io:           URI.open(cloudinary_link),
        filename:     "#{movie.api_movie_id}_poster.jpg",
        content_type: "image/jpeg"
      )
      puts "📌 Attached poster to ActiveStorage for '#{movie.title}'."
    end
  end

  # ----- BACKDROP (Active Storage + Cloudinary) -----
  if details["backdrop_path"].present?
    backdrop_public_id = "sart/movies/#{movie.api_movie_id}_backdrop"

    if cloudinary_resource_exists?(backdrop_public_id)
      puts "📌 Backdrop already exists on Cloudinary for '#{movie.title}'."
    else
      backdrop_url = "https://image.tmdb.org/t/p/original#{details['backdrop_path']}"
      puts "⬆️  Uploading backdrop for '#{movie.title}' as #{backdrop_public_id}..."
      Cloudinary::Uploader.upload(
        backdrop_url,
        public_id: backdrop_public_id,
        overwrite: false
      )
      puts "✅ Uploaded backdrop for '#{movie.title}'."
    end

    unless movie.backdrop.attached?
      cloudinary_link = Cloudinary::Utils.cloudinary_url(backdrop_public_id)
      movie.backdrop.attach(
        io:           URI.open(cloudinary_link),
        filename:     "#{movie.api_movie_id}_backdrop.jpg",
        content_type: "image/jpeg"
      )
      puts "📌 Attached backdrop to ActiveStorage for '#{movie.title}'."
    end
  end

  puts "Finished seeding '#{movie.title}'."
end

Movie.set_all_embeddings

# -----------------------------------------------------------------------------
# Section: Summary output
puts "🌟 Seeding complete!"
puts "🎞️  Total Movies:             #{Movie.count}"
puts "📚  Total Genres:             #{Genre.count}"
puts "🧑‍🎤  Total Cast Records:      #{Cast.count}"
puts "🎭  Total Character Records:  #{Character.count}"
puts "🎬  Total Directors:          #{Director.count}"
puts "🔗  Total Movie-Director Links: #{MovieDirector.count}"
puts "🖼️  Total Attachments:        #{ActiveStorage::Attachment.count}"
