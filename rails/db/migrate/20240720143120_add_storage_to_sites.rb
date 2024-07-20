class AddStorageToSites < ActiveRecord::Migration[7.1]
  def change
    add_column :sites, :storage_service, :string
    add_column :tspot_sites, :storage_service, :string
  end
end
