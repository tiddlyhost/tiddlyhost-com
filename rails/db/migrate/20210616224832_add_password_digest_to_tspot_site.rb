class AddPasswordDigestToTspotSite < ActiveRecord::Migration[6.1]
  def change
    add_column :tspot_sites, :password_digest, :string
  end
end
