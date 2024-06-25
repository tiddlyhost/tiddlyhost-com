# frozen_string_literal: true

class ReviseClassicEmptyDescription < ActiveRecord::Migration[7.0]

  def up
    # Should match what's in db/seeds/empties.yml
    EmptyMigrationHelper.apply_empty_changes(%{
      classic:
        description: The original version of TiddlyWiki from before the 2012 "TiddlyWiki5" rewrite.
        tooltip: Still used and developed by a small community. Fully supported on Tiddlyhost.
    })
  end

  def down
    # Don't try to put it back how it was
  end

end
