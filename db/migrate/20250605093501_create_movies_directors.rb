class CreateMoviesDirectors < ActiveRecord::Migration[7.1]
  def change
    create_table :movies_directors do |t|
      t.references :movie, null: false, foreign_key: true
      t.references :director, null: false, foreign_key: true

      t.timestamps
    end
  end
end
