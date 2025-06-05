# db/seeds.rb

# =============================================================================
# Seed Script: Populate the database with movie, genre, cast, character, and director data
#                AND attach each movie's poster and backdrop images to Cloudinary via Active Storage.
#
# Requirements:
#  • CLOUDINARY_URL or TMDB_API_KEY must be set in your environment (.env or elsewhere).
#  • config/storage.yml has a "cloudinary" service configured.
#  • config/environments/development.rb (or production.rb) uses:
#       config.active_storage.service = :cloudinary
#
# Workflow:
# 1) Clean out old records.
# 2) Fetch and save TMDB genres.
# 3) Fetch top-rated movies → for each:
#    a) Fetch detailed movie info (runtime + genres + poster/backdrop paths).
#    b) Create a Movie record.
#    c) Link its genres via movies_genres.
#    d) Fetch first 10 cast members → create Cast & Character records.
#    e) Fetch director from credits → create Director record (unless exists) → create MoviesDirector join.
#    f) Build full TMDB poster/backdrop URLs and attach via Active Storage.
# 4) Print summary counts.
# =============================================================================

require 'open-uri'  # so we can call URI.open(...) to download images
require 'net/http'
require 'uri'
require 'json'

# -----------------------------------------------------------------------------
# Section: Clean existing records
# We destroy all existing records (only if they exist) so we don't get duplicates.
# -----------------------------------------------------------------------------
puts "🧹 Cleaning database..."

# Destroy join table first to avoid FK issues
MovieDirector.destroy_all    if defined?(MovieDirector) && MovieDirector.any?
Director.destroy_all          if defined?(Director) && Director.any?
Character.destroy_all         if Character.any?
Cast.destroy_all              if Cast.any?
MoviesGenre.destroy_all       if MoviesGenre.any?
Movie.destroy_all             if Movie.any?
Genre.destroy_all             if Genre.any?

puts "✅ Cleaned."

# -----------------------------------------------------------------------------
# Section: API setup & helper
# We define TMDB base URL and a helper method to GET + parse JSON from TMDB.
# -----------------------------------------------------------------------------
API_TOKEN = ENV['TMDB_API_KEY']
BASE_URL   = "https://api.themoviedb.org/3"

def fetch_json(endpoint)
  # Build full URI: BASE_URL + endpoint string
  url = URI("#{BASE_URL}#{endpoint}")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  # Build GET request with TMDB credentials
  request = Net::HTTP::Get.new(url)
  request["accept"]        = "application/json"
  request["Authorization"] = "Bearer #{API_TOKEN}"

  # Execute & parse the response
  response = http.request(request)
  JSON.parse(response.body)
end

# -----------------------------------------------------------------------------
# Section: Fetch & create genres
# We pull TMDB's /genre/movie/list, then create each Genre record with:
#   • api_genre_id: TMDB's numeric ID
#   • name:          TMDB's genre name (e.g. "Action")
# -----------------------------------------------------------------------------
puts "🌱 Seeding genres..."
genre_data = fetch_json("/genre/movie/list?language=en")["genres"]

genre_data.each do |genre|
  Genre.create!(
    api_genre_id: genre["id"],
    name:         genre["name"]
  )
end

puts "✅ #{Genre.count} genres created."

# -----------------------------------------------------------------------------
# Section: Fetch & create top-rated movies + related data + image attachment
# 1) Pull /movie/top_rated (page 1).
# 2) For each movie in that list:
#    a) Pull /movie/:id    to get runtime, genres array, poster_path, backdrop_path.
#    b) Create Movie record with those attributes.
#    c) Link its genres using MoviesGenre.
#    d) Pull /movie/:id/credits, take the first 10 cast members → create Cast and Character.
#    e) From the same credits, find the Director → create Director record (unless exists) → join with MoviesDirector.
#    f) Attach poster and backdrop images via Active Storage (Cloudinary).
# -----------------------------------------------------------------------------
puts "🎬 Seeding top-rated movies (with genres, cast, characters, directors, and images)..."
movies_data = fetch_json("/movie/top_rated?language=en-US&page=1")["results"]

movies_data.each do |movie_data|
  # 2a) Fetch detailed info for this movie (including runtime, genres, poster_path, backdrop_path)
  details = fetch_json("/movie/#{movie_data['id']}?language=en-US")
  next unless details["title"].present?

  # 2b) Create the Movie record in our DB
  movie = Movie.create!(
    api_movie_id: details["id"],
    title:        details["title"],
    overview:     details["overview"],
    release_date: details["release_date"],
    runtime:      details["runtime"],
    popularity:   details["popularity"]
  )

  # 2c) Link genres to the new Movie:
  #     TMDB returns an array of genre hashes; each has an "id" we match to our local Genre.
  details["genres"].each do |genre_data|
    genre = Genre.find_by(api_genre_id: genre_data["id"])
    MoviesGenre.create!(movie: movie, genre: genre) if genre
  end

  # 2d) Fetch cast & crew list to populate Cast, Character, and Director tables
  credits = fetch_json("/movie/#{movie.api_movie_id}/credits")

  # Insert Cast & Character (first 10 cast members)
  cast_inserted      = 0
  character_inserted = 0

  credits["cast"].first(10).each do |cast_data|
    #  • Check if a Cast with this TMDB cast ID already exists (avoid duplicates)
    cast = Cast.find_by(api_cast_id: cast_data["id"])

    unless cast
      #  • If not, create a new Cast record
      cast = Cast.create!(
        api_cast_id: cast_data["id"],
        name:        cast_data["name"]
      )
      cast_inserted += 1
    end

    #  • Create the Character record linking this movie & this cast member
    Character.create!(
      movie:          movie,
      cast:           cast,
      character_name: cast_data["character"]
    )
    character_inserted += 1
  end

  # 2e) Find the Director(s) in crew
  director_inserted      = 0
  movie_director_inserted = 0

  credits["crew"].select { |crew_member| crew_member["job"] == "Director" }.each do |dir_data|
    #  • Check if Director with this TMDB cast ID already exists
    director = Director.find_by(api_cast_id: dir_data["id"])

    unless director
      #  • If not, create a new Director record
      director = Director.create!(
        api_cast_id: dir_data["id"],
        name:        dir_data["name"]
      )
      director_inserted += 1
    end

    #  • Create join table record linking movie & director (avoid duplicates)
    unless MovieDirector.exists?(movie: movie, director: director)
      MovieDirector.create!(movie: movie, director: director)
      movie_director_inserted += 1
    end
  end

  # 2f) Attach poster image via Active Storage
  if details["poster_path"].present?
    poster_url = "https://image.tmdb.org/t/p/original#{details['poster_path']}"
    poster_io  = URI.open(poster_url)
    movie.poster.attach(
      io:           poster_io,
      filename:     "#{movie.api_movie_id}_poster.jpg",
      content_type: poster_io.content_type
    )
  end

  # 2f) Attach backdrop image via Active Storage
  if details["backdrop_path"].present?
    backdrop_url = "https://image.tmdb.org/t/p/original#{details['backdrop_path']}"
    backdrop_io  = URI.open(backdrop_url)
    movie.backdrop.attach(
      io:           backdrop_io,
      filename:     "#{movie.api_movie_id}_backdrop.jpg",
      content_type: backdrop_io.content_type
    )
  end

  # Log how many cast, characters, directors, and joins were inserted for this movie
  puts "🎥 Created '#{movie.title}': "\
       "#{cast_inserted} new cast, "\
       "#{character_inserted} characters, "\
       "#{director_inserted} new director(s), "\
       "#{movie_director_inserted} movie-director join(s), "\
       "images attached."
end

# -----------------------------------------------------------------------------
# Section: Summary output
# After seeding everything, print totals so we can verify what got created.
# -----------------------------------------------------------------------------
puts "🌟 Seeding complete!"
puts "🎞️  Total Movies:             #{Movie.count}"
puts "📚  Total Genres:             #{Genre.count}"
puts "🧑‍🎤  Total Cast Records:       #{Cast.count}"
puts "🎭  Total Character Records:   #{Character.count}"
puts "🎬  Total Directors:           #{Director.count}"
puts "🔗  Total Movie-Director Links: #{MovieDirector.count}"
puts "🖼️  Total Attachments:         #{ActiveStorage::Attachment.count}"
