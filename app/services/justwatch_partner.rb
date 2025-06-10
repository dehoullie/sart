# app/services/justwatch_partner.rb
require 'httparty'

class JustwatchPartner
  BASE_URL = "https://apis.justwatch.com"

  def initialize(tmdb_id:, country: 'US')
    @tmdb_id = tmdb_id
    @country = country.upcase
  end

  def offers_with_urls
    fetch_offers.map do |offer|
      {
        url:           offer.dig('urls', 'standard_web'),
        provider_id:   offer['provider_id'],
        provider_name: offer['provider_name'],
        monetization:  offer['monetization_type']
      }
    end
  end

  private

  def fetch_offers
    url = "#{BASE_URL}/partner/content/titles/movie/tmdb/#{@tmdb_id}?country=#{@country}"
    Rails.logger.info "[JustwatchPartner] GET #{url}"
    resp = HTTParty.get(url, timeout: 5)
    Rails.logger.info "[JustwatchPartner] status: #{resp.code}"

    return [] unless resp.success?
    data = resp.parsed_response
    Rails.logger.info "[JustwatchPartner] data keys: #{data.keys.inspect}"
    data['offers'] || []
  rescue StandardError => e
    Rails.logger.error "[JustwatchPartner] Error: #{e.class} - #{e.message}"
    []
  end
end
