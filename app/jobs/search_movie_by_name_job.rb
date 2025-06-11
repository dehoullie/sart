class SearchMovieByNameJob < ApplicationJob
  queue_as :default

  require 'uri'
  require 'net/http'
  require 'cgi'
  TMDB_TOKEN = ENV.fetch("TMDB_API_KEY")

  def perform(query)
    tmdb_url = URI("https://api.themoviedb.org/3/search/movie?query=#{CGI.escape(query)}&include_adult=false&language=en-US&page=1")
    http     = Net::HTTP.new(tmdb_url.host, tmdb_url.port)
    http.use_ssl = true
    req      = Net::HTTP::Get.new(tmdb_url)
    req["Authorization"] = "Bearer #{TMDB_TOKEN}"
    req["Accept"]        = "application/json"
    tmdb_res = http.request(req)
    results  = JSON.parse(tmdb_res.body)["results"] || []

    if results.any?
      first_result = results.first
      movie_id = first_result["id"]
      chat = true
      SaveMovieJob.perform_later(movie_id, query, chat) if movie_id
    end
  end
end
