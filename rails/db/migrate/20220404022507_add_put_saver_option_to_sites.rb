class AddPutSaverOptionToSites < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :enable_put_saver, :boolean, default: false
  end
end
