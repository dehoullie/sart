class AddNameAndCountryToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :name, :string
    add_column :users, :country, :string
  end
end
