class AddSiteSearchFields < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :description, :string
    add_column :sites, :is_searchable, :boolean, default: false
  end
end
