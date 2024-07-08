class AddRedirectToTspotSites < ActiveRecord::Migration[6.1]
  def change
    add_column :tspot_sites, :redirect_to_site_id, :bigint
    add_column :tspot_sites, :redirect_to_url, :string
  end
end
