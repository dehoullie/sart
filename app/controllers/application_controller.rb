
class ApplicationController < ActionController::Base
  before_action :ensure_session_country

  private

  def ensure_session_country
    return if session[:country_code].present?

    ip = request.remote_ip
    return if ip == "127.0.0.1" || ip.start_with?("192.168.")

    if (loc = Geocoder.search(ip).first)
      session[:country_code] = loc.country_code.to_s.downcase
      return
    end

    begin
      require "net/http"
      require "json"

      url  = URI("https://ipapi.co/json/")
      resp = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.get(url)
      end

      if resp.is_a?(Net::HTTPSuccess)
        data = JSON.parse(resp.body)
        code = data["country_code"].to_s.downcase

        session[:country_code] = code if code.match?(/\A[a-z]{2}\z/)
      end
    rescue => e
      Rails.logger.warn "[CountryDetect] IP→country failed: #{e.message}"
    end
  end

  public

  def set_country
    session[:country_code] = params[:country_code].to_s.downcase
    @movie = Movie.find(params[:movie_id]) if params[:movie_id].present?

    respond_to do |format|
      format.turbo_stream do
        # Substitui o bloco "where_to_watch"
        ts1 = turbo_stream.replace(
                "where_to_watch",
                partial: "movies/where_to_watch",
                locals: { movie: @movie }
              )
        ts2 = turbo_stream.replace(
                "country_flag",
                partial: "shared/country_flag",
                locals: { country_code: session[:country_code].to_s.downcase }
              )
              render turbo_stream: [ts1, ts2]
      end

      format.html do
        redirect_back(fallback_location: root_path)
      end
    end
  end
end
