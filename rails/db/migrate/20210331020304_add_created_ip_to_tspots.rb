class AddCreatedIpToTspots < ActiveRecord::Migration[6.1]
  def change
    add_column :tspot_sites, :created_ip, :string
  end
end
