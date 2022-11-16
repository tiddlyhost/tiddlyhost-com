class AddPutSaverFields < ActiveRecord::Migration[6.1]
  def change
    # Preserve the value from the old field
    rename_column :sites, :enable_put_saver, :prefer_put_saver

    # New column for users who want to force upload saver
    add_column :sites, :prefer_upload_saver, :boolean, default: false
  end
end
