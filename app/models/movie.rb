class Movie < ApplicationRecord
  has_many :favorites, dependent: :destroy
  has_many :users, through: :favorites

  has_many :movies_genres, dependent: :destroy
  has_many :genres, through: :movies_genres

  has_many :characters, dependent: :destroy
  has_many :casts, through: :characters

  has_one_attached :poster
  has_one_attached :backdrop

  has_many :movie_directors, dependent: :destroy
  has_many :directors, through: :movie_directors

  has_neighbors :embedding
  after_create :set_embedding

  has_many :movie_directors # This refers to the join model
  has_many :directors, through: :movie_directors

  # after_create_commit do
  #   broadcast_append_to(
  #     "search_results_#{title.parameterize}",
  #     target: "results_list",
  #     partial: "shared/movie_card",
  #     locals: { movie: self }
  #   )
  # end

  COUNTRIES = [
            { code: 'de', name: 'Germany' },
            { code: 'us', name: 'United States' },
            { code: 'fr', name: 'France' },
            { code: 'es', name: 'Spain' },
            { code: 'it', name: 'Italy' },
            { code: 'gb', name: 'United Kingdom' },
            { code: 'pt', name: 'Portugal' },
            { code: 'br', name: 'Brazil' },
            { code: 'jp', name: 'Japan' },
            { code: 'cn', name: 'China' },
            { code: 'in', name: 'India' },
            { code: 'ru', name: 'Russia' },
            { code: 'ca', name: 'Canada' },
            { code: 'au', name: 'Australia' },
            { code: 'mx', name: 'Mexico' },
            { code: 'ar', name: 'Argentina' },
            { code: 'nl', name: 'Netherlands' },
            { code: 'be', name: 'Belgium' },
            { code: 'ch', name: 'Switzerland' },
            { code: 'se', name: 'Sweden' },
            { code: 'no', name: 'Norway' },
            { code: 'dk', name: 'Denmark' },
            { code: 'fi', name: 'Finland' },
            { code: 'pl', name: 'Poland' },
            { code: 'tr', name: 'Turkey' },
            { code: 'gr', name: 'Greece' },
            { code: 'ie', name: 'Ireland' },
            { code: 'at', name: 'Austria' },
            { code: 'cz', name: 'Czech Republic' },
            { code: 'hu', name: 'Hungary' },
            { code: 'ro', name: 'Romania' },
            { code: 'bg', name: 'Bulgaria' },
            { code: 'ua', name: 'Ukraine' },
            { code: 'za', name: 'South Africa' },
            { code: 'eg', name: 'Egypt' },
            { code: 'sa', name: 'Saudi Arabia' },
            { code: 'ae', name: 'United Arab Emirates' },
            { code: 'kr', name: 'South Korea' },
            { code: 'sg', name: 'Singapore' },
            { code: 'th', name: 'Thailand' },
            { code: 'id', name: 'Indonesia' },
            { code: 'my', name: 'Malaysia' },
            { code: 'ph', name: 'Philippines' },
            { code: 'vn', name: 'Vietnam' },
            { code: 'il', name: 'Israel' },
            { code: 'nz', name: 'New Zealand' },
            { code: 'cl', name: 'Chile' },
            { code: 'co', name: 'Colombia' },
            { code: 'pe', name: 'Peru' },
            { code: 've', name: 'Venezuela' }
          ]

  def self.set_all_embeddings
    Movie.all.each do |movie|
      movie.set_embedding
    end
  end

  def set_embedding
    client = OpenAI::Client.new
    response = client.embeddings(
      parameters: {
        model: 'text-embedding-3-small',
        input: "Movie title: #{title}. Movie overview: #{overview}"
      }
    )
    embedding = response['data'][0]['embedding']
    update!(embedding: embedding)
  end
end
