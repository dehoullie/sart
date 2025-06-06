# app/controllers/directors_controller.rb
class DirectorsController < ApplicationController
  def show
    @director = Director.find(params[:id])
    @movies = @director.movies.order(release_date: :desc) # Fetch director's movies

    # Explicitly render the view from app/views/casts/show.html.erb
    render 'casts/show'

  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Director not found." # Redirect if director doesn't exist
  end
end
