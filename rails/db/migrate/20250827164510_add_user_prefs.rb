class AddUserPrefs < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :preferences, :json, default: {}
  end
end
