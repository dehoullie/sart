class CountriesController < ApplicationController
  # POST /set_country
  def set
    code = params[:country_code].to_s.downcase
    unless code.match?(/\A[a-z]{2}\z/)
      return head :bad_request
    end

    session[:country_code] = code
    @movie = Movie.find(params[:movie_id]) if params[:movie_id].present?
    @providers = @movie ? MovieProvidersFetcher.new(tmdb_id: @movie.api_movie_id, country_code: code).call : nil

    respond_to do |format|
      format.turbo_stream {
        streams = []
        streams << turbo_stream.replace(
          "country_flag",
          partial: "shared/country_flag",
          locals: { country_code: code }
        )
        if @movie
          streams << turbo_stream.replace(
            "where_to_watch",
            partial: "movies/where_to_watch",
            locals: { movie: @movie, providers: @providers }
          )
        end
        render turbo_stream: streams
      }
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
