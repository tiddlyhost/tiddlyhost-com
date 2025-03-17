class AddExternalJsFeatherWikiEmpty < ActiveRecord::Migration[7.1]
  def up
    (Empty.find_or_create_by(name: 'featherx') do |e|
      e.title = 'Feather Wiki (external core)'
      e.description = 'Feathers & Bones version of Feather Wiki. Experimental tech-preview. Use with caution.'
      e.enabled = true
      e.info_link = 'https://feather.wiki/'
      e.display_order = 21
      e.primary = false
      e.tooltip = 'With external javascript the initial html file is just 616 bytes. Currently requires a custom build of Feather Wiki.'
    end).update(enabled: true) # Make sure it's enabled in case you did a rollback
  end

  def down
    # Disable it but don't delete it since there might be sites using it
    Empty.find_by_name('featherx')&.update(enabled: false)
  end
end
