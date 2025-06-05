class CreateDirectors < ActiveRecord::Migration[7.1]
  def change
    create_table :directors do |t|
      t.string :name
      t.integer :api_cast_id

      t.timestamps
    end
    add_index :directors, :api_cast_id, unique: true
  end
end
