class AddEmbeddingToMovies < ActiveRecord::Migration[7.1]
  def change
    add_column :movies, :embedding, :vector, limit: 1536
  end
end
