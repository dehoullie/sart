class DropMoviesDirectorsTable < ActiveRecord::Migration[7.0]
  def change
    # If your old join table is called "movies_directors", drop it:
    drop_table :movies_directors
  end
end
