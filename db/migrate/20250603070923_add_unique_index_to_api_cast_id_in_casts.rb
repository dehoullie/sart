class AddUniqueIndexToApiCastIdInCasts < ActiveRecord::Migration[7.1]
  def change
    add_index :casts, :api_cast_id, unique: true
  end
end
