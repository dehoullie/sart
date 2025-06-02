require 'uri'
require 'net/http'
require 'json'

puts "🧹 Cleaning database..."

Character.destroy_all if Character.any?
Cast.destroy_all if Cast.any?
MoviesGenre.destroy_all if MoviesGenre.any?
Movie.destroy_all if Movie.any?
Genre.destroy_all if Genre.any?

puts "✅ Cleaned."

API_TOKEN = ENV['TMDB_API_KEY']
BASE_URL = "https://api.themoviedb.org/3"

def fetch_json(endpoint)
  url = URI("#{BASE_URL}#{endpoint}")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request["accept"] = "application/json"
  request["Authorization"] = "Bearer #{API_TOKEN}"

  response = http.request(request)
  JSON.parse(response.body)
end

puts "🌱 Seeding genres..."
genre_data = fetch_json("/genre/movie/list?language=en")["genres"]
genre_data.each do |genre|
  Genre.create!(api_genre_id: genre["id"], name: genre["name"])
end
puts "✅ #{Genre.count} genres created."

puts "🎬 Seeding top-rated movies (with genres, cast, characters)..."
movies_data = fetch_json("/movie/top_rated?language=en-US&page=1")["results"]

movies_data.each do |movie_data|
  details = fetch_json("/movie/#{movie_data['id']}?language=en-US")
  next unless details["title"].present?

  movie = Movie.create!(
    api_movie_id: details["id"],
    title: details["title"],
    overview: details["overview"],
    release_date: details["release_date"],
    runtime: details["runtime"]
  )

  # Genres
  details["genres"].each do |genre_data|
    genre = Genre.find_by(api_genre_id: genre_data["id"])
    MoviesGenre.create!(movie: movie, genre: genre) if genre
  end

  # Cast & Characters
  credits = fetch_json("/movie/#{movie.api_movie_id}/credits")
  credits["cast"].first(10).each do |cast_data|
    cast = Cast.find_or_create_by!(api_cast_id: cast_data["id"]) do |c|
      c.name = cast_data["name"]
    end

    Character.create!(
      movie: movie,
      cast: cast,
      character_name: cast_data["character"]
    )
  end

  puts "🎥 #{movie.title} created with genres and cast"
end

puts "🌟 Seeding complete! #{Movie.count} movies with genres and cast."
