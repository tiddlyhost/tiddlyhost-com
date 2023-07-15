class ReviseFeatherwikiDescription < ActiveRecord::Migration[7.0]

  def up
    # Should match what's in db/seeds/empties.yml
    EmptyMigrationHelper.apply_empty_changes(%{
      feather:
        description: A modern and light-weight single-page wiki with support for
          both Markdown and WYSIWYG
        tooltip: Feather Wiki is very small (around 50 KB) but it's extensible,
          supports tagging, custom styles, publish mode, and more.
    })
  end

  def down
  end

end
