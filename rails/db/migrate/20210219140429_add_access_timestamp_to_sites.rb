class AddAccessTimestampToSites < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :accessed_at, :datetime
  end
end
