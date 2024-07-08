class AddSiteSaveCount < ActiveRecord::Migration[6.1]
  def up
    add_column :sites, :save_count, :integer, default: 0

    # For existing sites we don't know their save count, but
    # one is a much better guess than zero.
    Site.updated_at_least_once.update_all(save_count: 1)
  end

  def down
    remove_column :sites, :save_count
  end
end
