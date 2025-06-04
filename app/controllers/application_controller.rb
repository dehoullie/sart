class ApplicationController < ActionController::Base
  # before_action :authenticate_user!
  before_action :ensure_session_country

  private

  def ensure_session_country
    return if session[:country_code].present?

    # Skip localhost or private‐IP in development:
    ip = request.remote_ip
    return if ip == "127.0.0.1" || ip.start_with?("192.168.")

    # Example: Geocoder gem approach (if you've configured Geocoder for IP lookups)
    if (loc = Geocoder.search(ip).first)
      session[:country_code] = loc.country_code.to_s.downcase
      return
    end

    # Otherwise, fallback to plain ipapi.co
    begin
      require "net/http"
      require "json"
      url  = URI("https://ipapi.co/json/")
      resp = Net::HTTP.start(url.host, url.port, use_ssl: true) { |http| http.get(url) }
      if resp.is_a?(Net::HTTPSuccess)
        data = JSON.parse(resp.body)
        code = data["country_code"].to_s.downcase
        session[:country_code] = code if code.match?(/\A[a-z]{2}\z/)
      end
    rescue => e
      Rails.logger.warn "[CountryDetect] IP→country failed: #{e.message}"
    end
  end
end
