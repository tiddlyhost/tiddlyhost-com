class AddTwKindToSite < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :tw_kind, :string
    add_column :tspot_sites, :tw_kind, :string
  end
end
