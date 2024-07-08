class AddAllowInIframeToSite < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :allow_in_iframe, :boolean, default: false
    add_column :tspot_sites, :allow_in_iframe, :boolean, default: false
  end
end
