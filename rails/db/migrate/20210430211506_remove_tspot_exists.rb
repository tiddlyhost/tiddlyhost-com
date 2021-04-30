class RemoveTspotExists < ActiveRecord::Migration[6.1]
  def change
    remove_column :tspot_sites, :exists, :boolean
  end
end
