class CreateMovies < ActiveRecord::Migration[7.1]
  def change
    create_table :movies do |t|
      t.string :title
      t.text :overview
      t.date :release_date
      t.integer :api_movie_id
      t.integer :runtime

      t.timestamps
    end
  end
end
