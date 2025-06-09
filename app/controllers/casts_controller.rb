class CastsController < ApplicationController
  def index
    @cast = Casts.find(params[:id])
    @movies = @cast.movies.order(release_date: :desc)

    # Fetch extended info from TMDb
    require 'uri'
    require 'net/http'

    tmdb_id = @cast.api_cast_id
    url = URI("https://api.themoviedb.org/3/person/#{tmdb_id}?language=en-US")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['accept'] = 'application/json'
    request['Authorization'] = "Bearer #{ENV['TMDB_API_KEY']}"
    response = http.request(request)
    @tmdb_director = JSON.parse(response.body)
  end

  def show
    @cast = Cast.find(params[:id])
    @movies = @cast.movies.order(release_date: :desc)

    # Fetch extended info from TMDb
    require 'uri'
    require 'net/http'

    tmdb_id = @cast.api_cast_id
    url = URI("https://api.themoviedb.org/3/person/#{tmdb_id}?language=en-US")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['accept'] = 'application/json'
    request['Authorization'] = "Bearer #{ENV['TMDB_API_KEY']}"
    response = http.request(request)
    @tmdb_cast = JSON.parse(response.body)
  end
end
