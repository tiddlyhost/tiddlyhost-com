class AddTwVersionToSite < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :tw_version, :string
    add_column :tspot_sites, :tw_version, :string
  end
end
