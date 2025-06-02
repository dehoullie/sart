class CreateGenres < ActiveRecord::Migration[7.1]
  def change
    create_table :genres do |t|
      t.string :name
      t.integer :api_genre_id

      t.timestamps
    end
  end
end
