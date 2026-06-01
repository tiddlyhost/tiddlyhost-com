class ModifyTw5EmptyName < ActiveRecord::Migration[8.0]
  def up
    EmptyMigrationHelper.apply_empty_changes(%(
      tw5:
        title: TiddlyWiki
    ))
  end

  def down
    EmptyMigrationHelper.apply_empty_changes(%(
      tw5:
        title: TiddlyWiki (self-contained)
    ))
  end
end
