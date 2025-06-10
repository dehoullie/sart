require 'uri'
require 'net/http'
require 'json'

class SaveListJob < ApplicationJob
  queue_as :default

  TMDB_API_URL = "https://api.themoviedb.org/3/movie"
  API_TOKEN = ENV['TMDB_API_KEY']

  def perform(list_name, pages)
    puts "Starting SaveListJob for '#{list_name}' with #{pages} page(s)..."
    (1..pages).each do |page|
      puts "Fetching page #{page} of '#{list_name}'..."
      url = URI("#{TMDB_API_URL}/#{list_name}?language=en-US&page=#{page}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(url)
      request["accept"] = 'application/json'
      request["Authorization"] = "Bearer #{API_TOKEN}"

      response = http.request(request)
      data = JSON.parse(response.body)

      if data["results"]
        puts "Found #{data['results'].size} movies on page #{page}."
        data["results"].each do |movie|
          puts "Enqueuing SaveMovieJob for movie ID #{movie['id']} (#{movie['title']})"
          SaveMovieJob.perform_later(movie["id"])
        end
      else
        puts "No results found on page #{page}."
      end
    end
    puts "Finished SaveListJob for '#{list_name}'."
  end
end
