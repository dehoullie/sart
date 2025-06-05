class CreateMovieDirectors < ActiveRecord::Migration[7.0]
  def change
    create_table :movie_directors do |t|
      t.references :movie,    null: false, foreign_key: true
      t.references :director, null: false, foreign_key: true

      t.timestamps
    end

    # Prevent the same (movie, director) pair from being inserted twice:
    add_index :movie_directors, [:movie_id, :director_id], unique: true
  end
end
