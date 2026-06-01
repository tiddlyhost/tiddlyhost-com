class ModifyFeatherxEmpty < ActiveRecord::Migration[8.0]
  def up
    # Should match what's in db/seeds/empties.yml
    EmptyMigrationHelper.apply_empty_changes(%(
      featherx:
        description: The super-light Feather Wiki build with external Javascript and
          CSS. Less self-contained, but very fast to load and save.
        tooltip: For the "bones, plumage and muscles" build of Feather Wiki, the initial
          empty file is around 700 bytes.
        primary: true
    ))
  end

  def down
    # Never mind
  end
end
