# frozen_string_literal: true

class BlessTw5xEmpty < ActiveRecord::Migration[6.1]
  def up
    EmptyMigrationHelper.apply_empty_changes(%{
      tw5x:
        title: TiddlyWiki (external core)
        description: >-
          The famous customizable personal wiki and non-linear
          notebook, with external core javascript
        info_link: https://tiddlywiki.com/
        tooltip: >-
          With the core plugin hosted externally the site will be smaller, loading
          and saving will be faster, but the downloaded TiddlyWiki file won't work
          without internet access.
        display_order: 12
        primary: true
        enabled: true

      tw5:
        title: TiddlyWiki (self-contained)
        description: >-
          The famous customizable personal wiki and non-linear
          notebook, with internal core javascript
        info_link: https://tiddlywiki.com/
        tooltip: >-
          With an internal core plugin the site will be larger, loading and saving
          will be slower, but the downloaded TiddlyWiki file will be usable offline
          even without internet access.
        display_order: 10
        primary: true
        enabled: true
    })
  end

  def down
  end
end
