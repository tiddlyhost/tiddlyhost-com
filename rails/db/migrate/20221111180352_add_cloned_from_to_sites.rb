# frozen_string_literal: true

class AddClonedFromToSites < ActiveRecord::Migration[6.1]
  def change
    # No foreign key reference because the site could be be deleted later
    add_reference :sites, :cloned_from #, foreign_key: { to_table: :sites }
  end
end
