# lib/tmdb_scraper.rb
require 'httparty'
require 'nokogiri'

class TmdbScraper
  BASE_URL = 'https://www.themoviedb.org/movie'.freeze

  def initialize(movie_id, locale = 'en-US')
    @url = "#{BASE_URL}/#{movie_id}/watch?locale=#{locale}"
  end

  def fetch_offers
    Rails.logger.info "[TmdbScraper] Fetching providers from #{@url}"

    response = HTTParty.get(@url)
    return {} unless response.code == 200

    doc = Nokogiri::HTML(response.body)
    result = { link: @url }

    doc.css('div.ott_provider').each do |section|      title = section.at_css('h3')&.text&.strip&.downcase
      next unless title

      providers = section.css('ul.providers li a').map do |a|
        {
          url: a['href'],
          logo_url: a.at_css('img')&.[]('src'),
          provider_name: a['title'],
          monetization: title
        }
      end

      case title
      when 'stream'
        result[:flatrate] = providers
      when 'rent'
        result[:rent] = providers
      when 'buy'
        result[:buy] = providers
      end
    end

    result
  rescue StandardError => e
    Rails.logger.error "[TmdbScraper] Error: #{e.class} - #{e.message}"
    {}
  end
end
