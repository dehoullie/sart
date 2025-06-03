class MoviesController < ApplicationController
  def index
    q = params[:query].to_s.strip if params[:query].present?

    if q.present?
      # User submitted a non‐empty search. Return just the search results partial.
      @movies = Movie.where("title ILIKE ?", "%#{q}%").limit(10)
      render partial: "results", locals: { movies: @movies }
    else
      # No search term: render the full index (banner + home-content) as normal
      @movies       = Movie.limit(3)                            # for banner & home-content
      @last_three = Movie.all.sample(3) if Movie.count > 3 # for banner
      @genres       = Genre.all                                  # if home-content needs it
      @recent_movies = Movie.order(created_at: :desc).limit(6)   # if home-content needs it

      respond_to do |format|
        format.html   # will render app/views/movies/index.html.erb
      end
    end
  end

  # other actions (show, etc.) remain unchanged
end
