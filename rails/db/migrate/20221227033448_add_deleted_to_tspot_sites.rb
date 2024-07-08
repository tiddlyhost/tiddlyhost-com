class AddDeletedToTspotSites < ActiveRecord::Migration[6.1]
  def change
    add_column :tspot_sites, :deleted, :boolean, default: false
  end
end
