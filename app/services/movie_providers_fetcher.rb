# app/services/movie_providers_fetcher.rb
class MovieProvidersFetcher
  TMDB_BASE_URL = "https://api.themoviedb.org/3"

  def initialize(tmdb_id:, country_code:)
    @tmdb_id      = tmdb_id
    @country_code = country_code.to_s.upcase
  end

  def call
    raw = fetch_watch_providers_json
    return empty_hash if raw.nil?

    data = raw.dig("results", @country_code)
    return empty_hash unless data.is_a?(Hash)

    {
      flatrate: build_list(data["flatrate"]),
      rent:     build_list(data["rent"]),
      buy:      build_list(data["buy"]),
      link:     data["link"]
    }
  end

  private
class MovieProvidersFetcher
  TMDB_BASE_URL = "https://api.themoviedb.org/3"

  def initialize(tmdb_id:, country_code:)
    @tmdb_id      = tmdb_id
    @country_code = country_code.to_s.upcase
  end

  def call
    raw = fetch_watch_providers_json
    return empty_hash if raw.nil?

    data = raw.dig("results", @country_code)
    return empty_hash unless data.is_a?(Hash)

    {
      flatrate: build_list(data["flatrate"]),
      rent:     build_list(data["rent"]),
      buy:      build_list(data["buy"]),
      link:     data["link"]
    }
  end

  private

  def empty_hash
    { flatrate: [], rent: [], buy: [], link: nil }
  end

  def fetch_watch_providers_json
    url = URI("#{TMDB_BASE_URL}/movie/#{@tmdb_id}/watch/providers")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    req = Net::HTTP::Get.new(url)
    req["accept"]        = "application/json"
    req["Authorization"] = "Bearer #{ENV.fetch("TMDB_API_KEY")}"

    resp = http.request(req)
    return nil unless resp.is_a?(Net::HTTPSuccess)
    JSON.parse(resp.body)
  rescue StandardError
    nil
  end

  def build_list(raw_array)
    return [] unless raw_array.is_a?(Array)
    raw_array.map do |prov|
      { name: prov["provider_name"], logo_url: full_url(prov["logo_path"]) }
    end
  end

  def full_url(path)
    return nil if path.nil? || path.empty?
    "https://image.tmdb.org/t/p/original#{path}"
  end
end
  def empty_hash
    { flatrate: [], rent: [], buy: [], link: nil }
  end

  def fetch_watch_providers_json
    url = URI("#{TMDB_BASE_URL}/movie/#{@tmdb_id}/watch/providers")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    req = Net::HTTP::Get.new(url)
    req["accept"]        = "application/json"
    req["Authorization"] = "Bearer #{ENV.fetch("TMDB_API_KEY")}"

    resp = http.request(req)
    return nil unless resp.is_a?(Net::HTTPSuccess)
    JSON.parse(resp.body)
  rescue StandardError
    nil
  end

  def build_list(raw_array)
    return [] unless raw_array.is_a?(Array)
    raw_array.map { |prov| { name: prov["provider_name"], logo_url: full_url(prov["logo_path"]) } }
  end

  def full_url(path)
    return nil if path.nil? || path.empty?
    "https://image.tmdb.org/t/p/original#{path}"
  end
end
