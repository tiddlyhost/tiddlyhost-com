class AddPubliclyCloneableToSites < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :allow_public_clone, :boolean, default: false
  end
end
