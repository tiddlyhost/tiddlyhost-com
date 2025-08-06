class AddSiteleteerEmpty < ActiveRecord::Migration[7.2]
  def up
    Empty.find_or_create_by(name: 'sitelet') do |e|
      e.title = 'siteleteer'
      e.description = 'An even lighter and simpler single-page wiki from
        the creator of Feather Wiki.'.squish
      e.enabled = true
      e.info_link = 'https://alamantus.codeberg.page/siteleteer/'
      e.display_order = 25
      e.primary = false
      e.tooltip = 'To see how it works, view the clean and very readable page
        source. Requires a custom build of siteleteer.'.squish
    end.update(enabled: true) # Make sure it's enabled in case you did a rollback
  end

  def down
    # Disable it but don't delete it since there might be sites using it
    Empty.find_by_name('sitelet').update(enabled: false)
  end
end
