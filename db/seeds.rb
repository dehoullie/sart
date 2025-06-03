# db/seeds.rb

# =============================================================================
# Seed Script: Populate the database with movie, genre, cast, and character data
# This script fetches data from The Movie Database (TMDB) API and uses it to
# create local records for genres, top-rated movies, their associated genres,
# cast members, and the characters they portray. Existing records are cleared
# before seeding to avoid duplicates.
# =============================================================================

require 'uri'
require 'net/http'
require 'json'

# -----------------------------------------------------------------------------
# Section: Clean existing records
# We destroy all existing records for characters, cast, movie-genre associations,
# movies, and genres, but only if they already exist. This ensures a fresh start
# each time the seed is run.
# -----------------------------------------------------------------------------
puts "🧹 Cleaning database..."

# Only destroy Character records if any exist
Character.destroy_all if Character.any?

# Only destroy Cast records if any exist
Cast.destroy_all if Cast.any?

# Only destroy MoviesGenre join records if any exist
MoviesGenre.destroy_all if MoviesGenre.any?

# Only destroy Movie records if any exist
Movie.destroy_all if Movie.any?

# Only destroy Genre records if any exist
Genre.destroy_all if Genre.any?

puts "✅ Cleaned."

# -----------------------------------------------------------------------------
# Section: API setup and helper method
# Define the base URL for TMDB and a helper method `fetch_json` that handles
# HTTP GET requests to the TMDB API and parses the JSON response.
# -----------------------------------------------------------------------------
API_TOKEN = ENV['TMDB_API_KEY']
BASE_URL = "https://api.themoviedb.org/3"

# Helper method to send GET requests to the TMDB API and parse JSON
def fetch_json(endpoint)
  # Construct the full URL by combining the base URL and endpoint
  url = URI("#{BASE_URL}#{endpoint}")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  # Build the HTTP GET request, including the TMDB API authorization header
  request = Net::HTTP::Get.new(url)
  request["accept"] = "application/json"
  request["Authorization"] = "Bearer #{API_TOKEN}"

  # Execute the request and parse the JSON response
  response = http.request(request)
  JSON.parse(response.body)
end

# -----------------------------------------------------------------------------
# Section: Fetch and create genres
# Retrieve the list of movie genres from TMDB and store each as a Genre record.
# Each genre is saved with its TMDB `api_genre_id` and name.
# -----------------------------------------------------------------------------
puts "🌱 Seeding genres..."
genre_data = fetch_json("/genre/movie/list?language=en")["genres"]

genre_data.each do |genre|
  # Create a new Genre record using the TMDB genre ID for reference
  Genre.create!(api_genre_id: genre["id"], name: genre["name"])
end

# Log how many genres were created in total
puts "✅ #{Genre.count} genres created."

# -----------------------------------------------------------------------------
# Section: Fetch and create top-rated movies, their genres, cast, and characters
# 1. Retrieve the first page of top-rated movies from TMDB.
# 2. For each movie, fetch detailed info (including runtime and genres).
# 3. Create a Movie record.
# 4. Link the Movie to its genres via the movies_genres join table.
# 5. Fetch the cast list (first 10 members) for each movie and insert Cast and
#    Character records, avoiding duplicate cast entries based on `api_cast_id`.
# -----------------------------------------------------------------------------
puts "🎬 Seeding top-rated movies (with genres, cast, characters)..."
movies_data = fetch_json("/movie/top_rated?language=en-US&page=1")["results"]

movies_data.each do |movie_data|
  # Fetch full movie details to obtain runtime and genre information
  details = fetch_json("/movie/#{movie_data['id']}?language=en-US")
  # Skip if the movie title is missing
  next unless details["title"].present?

  # Create the Movie record with fields from the TMDB detail response
  movie = Movie.create!(
    api_movie_id: details["id"],
    title: details["title"],
    overview: details["overview"],
    release_date: details["release_date"],
    runtime: details["runtime"]
  )

  # -----------------------------------------------------------------------------
  # Link genres to the created movie:
  # For each genre in the movie details, find the local Genre record by TMDB ID
  # and create an association through the MoviesGenre join table.
  # -----------------------------------------------------------------------------
  details["genres"].each do |genre_data|
    genre = Genre.find_by(api_genre_id: genre_data["id"])
    MoviesGenre.create!(movie: movie, genre: genre) if genre
  end

  # -----------------------------------------------------------------------------
  # Fetch the cast list (first 10 members) for the movie:
  # For each cast member:
  # - Check if a Cast record with the same api_cast_id already exists.
  # - If not, create a new Cast record with name and api_cast_id.
  # - In either case, create a Character record linking the movie, cast, and
  #   the character name from the API response.
  # -----------------------------------------------------------------------------
  credits = fetch_json("/movie/#{movie.api_movie_id}/credits")
  cast_inserted = 0
  character_inserted = 0

  credits["cast"].first(10).each do |cast_data|
    # Attempt to find an existing Cast by TMDB ID to avoid duplicates
    cast = Cast.find_by(api_cast_id: cast_data["id"])
    unless cast
      # Create a new Cast record with the TMDB cast ID and actor name
      cast = Cast.create!(
        api_cast_id: cast_data["id"],
        name: cast_data["name"]
      )
      cast_inserted += 1
    end

    # Create the Character record linking the movie and cast, storing role name
    Character.create!(
      movie: movie,
      cast: cast,
      character_name: cast_data["character"]
    )
    character_inserted += 1
  end

  # Log how many new cast members and characters were inserted for this movie
  puts "🎥 #{movie.title} created with #{cast_inserted} new cast members and #{character_inserted} characters"
end

# -----------------------------------------------------------------------------
# Summary output
# After all seeding is done, log the total counts for movies, genres, cast, and
# characters to give a quick overview of the seeded data.
# -----------------------------------------------------------------------------
puts "🌟 Seeding complete!"
puts "🎞️  Total Movies: #{Movie.count}"
puts "📚 Total Genres: #{Genre.count}"
puts "🧑‍🎤 Total Casts: #{Cast.count}"
puts "🎭 Total Characters: #{Character.count}"
