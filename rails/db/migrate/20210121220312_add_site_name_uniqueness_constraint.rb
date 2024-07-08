class AddSiteNameUniquenessConstraint < ActiveRecord::Migration[6.1]
  def change
    add_index :sites, :name, unique: true
  end
end
