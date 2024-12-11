class SkipEtagCheck < ActiveRecord::Migration[7.1]
  def change
    add_column :sites, :skip_etag_check, :boolean, default: false
  end
end
