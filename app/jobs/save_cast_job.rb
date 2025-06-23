class SaveCastJob < ApplicationJob
  queue_as :default

  API_TOKEN = ENV['TMDB_API_KEY']
  BASE_URL  = 'https://api.themoviedb.org/3'

  def perform(api_movie_id)
    movie = Movie.find_by(api_movie_id: api_movie_id)
    return unless movie

    credits = fetch_json("/movie/#{api_movie_id}/credits")

    # Cast & Characters
    credits['cast'].first(10).each do |cast_data|
      cast = Cast.find_or_create_by!(api_cast_id: cast_data['id']) do |c|
        c.name = cast_data['name']
      end

      if cast_data['profile_path'].present? && !cast.photo.attached?
        profile_public_id = "sart/cast/#{cast.api_cast_id}_profile"

        unless cloudinary_resource_exists?(profile_public_id)
          profile_url = "https://image.tmdb.org/t/p/original#{cast_data['profile_path']}"
          Cloudinary::Uploader.upload(
            profile_url,
            public_id: profile_public_id,
            overwrite: false
          )
        end

        cloudinary_link = Cloudinary::Utils.cloudinary_url(profile_public_id)
        cast.photo.attach(
          io: URI.open(cloudinary_link),
          filename: "#{cast.api_cast_id}_profile.jpg",
          content_type: "image/jpeg"
        )
      end

      Character.find_or_create_by!(movie: movie, cast: cast) do |ch|
        ch.character_name = cast_data['character']
      end
    end

    # Directors
    credits['crew'].select { |c| c['job'] == 'Director' }.each do |dir_data|
      director = Director.find_or_create_by!(api_cast_id: dir_data['id']) do |d|
        d.name = dir_data['name']
      end
      MovieDirector.find_or_create_by!(movie: movie, director: director)
    end
  end

  private

  def fetch_json(endpoint)
    uri  = URI("#{BASE_URL}#{endpoint}")
    http = Net::HTTP.new(uri.host, uri.port).tap { |h| h.use_ssl = true }
    req  = Net::HTTP::Get.new(uri)
    req['accept']        = 'application/json'
    req['Authorization'] = "Bearer #{API_TOKEN}"
    JSON.parse(http.request(req).body)
  end

  def cloudinary_resource_exists?(public_id)
    Cloudinary::Api.resource(public_id)
    true
  rescue Cloudinary::Api::NotFound
    false
  end
end
