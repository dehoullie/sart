class CreateCharacters < ActiveRecord::Migration[7.1]
  def change
    create_table :characters do |t|
      t.references :cast, null: false, foreign_key: true
      t.references :movie, null: false, foreign_key: true
      t.string :character_name

      t.timestamps
    end
  end
end
