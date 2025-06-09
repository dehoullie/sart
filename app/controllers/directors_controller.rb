# app/controllers/directors_controller.rb
class DirectorsController < ApplicationController
  def show
    @director = Director.find(params[:id])
    @movies = @director.movies.order(release_date: :desc) # Fetch director's movies

    # Fetch extended info from TMDb
    require 'uri'
    require 'net/http'

    tmdb_id = @director.api_cast_id
    url = URI("https://api.themoviedb.org/3/person/#{tmdb_id}?language=en-US")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['accept'] = 'application/json'
    request['Authorization'] = "Bearer #{ENV['TMDB_API_KEY']}"
    response = http.request(request)
    @tmdb_director = JSON.parse(response.body)

    # Explicitly render the view from app/views/casts/show.html.erb
    # render 'casts/show'

  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Director not found." # Redirect if director doesn't exist
  end
end
