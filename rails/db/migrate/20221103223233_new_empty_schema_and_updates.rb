# frozen_string_literal: true

class NewEmptySchemaAndUpdates < ActiveRecord::Migration[6.1]
  def up
    add_column :empties, :display_order, :integer, default: 100
    add_column :empties, :primary, :bool, default: false
    add_column :empties, :info_link, :string
    add_column :empties, :tooltip, :string

    Empty.reset_column_information

    data = YAML.load(<<-EOT.strip_heredoc)
      tw5:
        description: The latest version of the famous single-page personal wiki and non-linear notebook
        info_link: https://tiddlywiki.com/
        tooltip: >-
          The popular and ground-breaking TiddlyWiki is powerful, extensible, and
          endlessly customizable. The default choice and the reason Tiddlyhost was
          created.
        display_order: 10
        primary: true

      feather:
        description: A new, modern, light-weight single-page wiki with Markdown and WYSIWYG support
        info_link: https://feather.wiki/
        tooltip: >-
          The new kid on the block, Feather Wiki, weighs in at only 50
          KB yet still manages to support tagging, customizable styles, publish
          mode, and more.
        title: Feather Wiki
        display_order: 20
        primary: true

      classic:
        description: The original old version of TiddlyWiki, retired from active development in 2011
        info_link: https://classic.tiddlywiki.com/
        tooltip: >-
          Still receives the occasional maintenance update and is
          fully supported on Tiddlyhost. Use for the nostalgia or to revive old
          TiddlyWikis in their original form.
        display_order: 30

      prerelease:
        description: The potentially unstable latest nightly build of TiddlyWiki
        info_link: https://tiddlywiki.com/prerelease/
        tooltip: >-
          Not recommended for serious use since it might have bugs or incomplete
          new features. Use this to test or preview the next version of TiddlyWiki.
        title: TiddlyWiki prerelease build
        display_order: 40

    EOT

    data.each do |empty_name, fields|
      Empty.find_by_name(empty_name)&.update(fields)
    end
  end

  def down
    remove_column :empties, :tooltip
    remove_column :empties, :info_link
    remove_column :empties, :primary
    remove_column :empties, :display_order
  end
end
