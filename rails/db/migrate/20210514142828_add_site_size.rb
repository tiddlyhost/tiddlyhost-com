class AddSiteSize < ActiveRecord::Migration[6.1]

  def change
    # This will be the uncompressed byte size. The compressed
    # byte size is already available via the blob record.
    #
    add_column :sites, :raw_byte_size, :integer
    add_column :tspot_sites, :raw_byte_size, :integer
  end

end
