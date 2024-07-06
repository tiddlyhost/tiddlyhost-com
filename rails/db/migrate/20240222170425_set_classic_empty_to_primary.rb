# frozen_string_literal: true

class SetClassicEmptyToPrimary < ActiveRecord::Migration[7.1]
  def up
    # Should match what's in db/seeds/empties.yml
    EmptyMigrationHelper.apply_empty_changes(%(
      classic:
        primary: true
    ))
  end

  def down
    EmptyMigrationHelper.apply_empty_changes(%(
      classic:
        primary: false
    ))
  end
end
