class AddAccessCountToSites < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :access_count, :integer, default: 0
  end
end
