class MoviesController < ApplicationController
  def index
    q = params[:query].to_s.strip if params[:query].present?

    if q.present?
      # User submitted a non‐empty search. Return just the search results partial.
      @movies = Movie
        .left_outer_joins(characters: :cast)
        .where(
          "movies.title ILIKE :q
           OR movies.overview ILIKE :q
           OR characters.character_name ILIKE :q
           OR casts.name ILIKE :q",
          q: "%#{q}%"
        )
        .distinct
        .order(popularity: :desc)
        .limit(10)
      render partial: "shared/results", locals: { movies: @movies }
    else
      # No search term: render the full index (banner + home-content) as normal
      @movies       = Movie.limit(3)                            # for banner & home-content
      @last_three = Movie.order(popularity: :desc).limit(3) if Movie.count > 3 # for banner
      # Get a list of 5 genres with most count movies
      @top_genres   = Genre
        .left_joins(:movies)
        .group(:id)
        .order("COUNT(movies.id) DESC")
        .limit(5)
      @genres       = Genre.all
      # Popular movies for the home-content section order by popularity column in the movies table
      @popular_movies = Movie.order(popularity: :desc).limit(5)

      respond_to do |format|
        format.html   # will render app/views/movies/index.html.erb
      end
    end
  end

  # other actions (show, etc.) remain unchanged
end
