class AddTw5pEmpty < ActiveRecord::Migration[7.2]
  def up
    Empty.find_or_create_by(name: 'tw5p') do |e|
      e.title = 'TiddlyWiki (previous version)'
      e.description = 'The previous stable version of TiddlyWiki, with internal core javascript.'.squish
      e.enabled = true
      e.info_link = 'https://tiddlywiki.com/'
      e.display_order = 39
      e.primary = false
      e.tooltip = "It's recommended to use the latest version, but this older
        version is available if needed, e.g. for plugin compatibility reasons.".squish
    end.update(enabled: true) # Make sure it's enabled in case you did a rollback
  end

  def down
    # Disable it but don't delete it since there might be sites using it
    Empty.find_by_name('tw5p').update(enabled: false)
  end
end
