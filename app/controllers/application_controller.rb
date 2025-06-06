require "net/http"
require "json"

class ApplicationController < ActionController::Base
  before_action :ensure_session_country

  private

  def ensure_session_country
    return if session[:country_code].present?

    ip = request.remote_ip
    Rails.logger.info "[CountryDetect] Detected IP: #{ip}"
    return if ip == "127.0.0.1" || ip.start_with?("192.168.")

    if (loc = Geocoder.search(ip).first)
      Rails.logger.info "[CountryDetect] Geocoder found: #{loc.country_code}"
      session[:country_code] = loc.country_code.to_s.downcase
      return
    end

    begin
      url  = URI("https://ipapi.co/json/")
      Rails.logger.info "[CountryDetect] Fetching from ipapi.co"
      resp = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.get(url)
      end

      Rails.logger.info "[CountryDetect] ipapi.co response: #{resp.code} #{resp.body}"

      if resp.is_a?(Net::HTTPSuccess)
        data = JSON.parse(resp.body)
        code = data["country_code"].to_s.downcase
        Rails.logger.info "[CountryDetect] ipapi.co country_code: #{code}"

        session[:country_code] = code if code.match?(/\A[a-z]{2}\z/)
      else
        Rails.logger.warn "[CountryDetect] ipapi.co failed or quota exceeded, defaulting to 'de'"
        session[:country_code] = "de"
      end
    rescue => e
      Rails.logger.warn "[CountryDetect] IP→country failed: #{e.message}, defaulting to 'de'"
      session[:country_code] = "de"
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
