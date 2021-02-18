class AddViewCountToSites < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :view_count, :integer, default: 0
  end
end
