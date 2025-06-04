class CountriesController < ApplicationController
  # POST /set_country
  def set
    code = params[:country_code].to_s.downcase
    unless code.match?(/\A[a-z]{2}\z/)
      return head :bad_request
    end

    session[:country_code] = code

    respond_to do |format|
      format.turbo_stream {
        # This replaces the entire <turbo-frame id="country_flag">…</turbo-frame>
        render turbo_stream: turbo_stream.replace(
          "country_flag",
          partial: "shared/country_flag",
          locals: { country_code: code }
        )
      }
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
