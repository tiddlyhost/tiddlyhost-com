class Add52Empty < ActiveRecord::Migration[6.1]

  def up
    (Empty.find_or_create_by(name: 'prerelease') do |e|
      e.title = 'TiddlyWiki 5.2.0 Pre-release'
      e.description = '(Jul 15 2021)'
      e.enabled = true
    end).update(enabled: true) # Make sure it's enabled in case you did a rollback

    # Disable the old preview
    Empty.find_by_name('tw5-json-store-test').update(enabled: false)
  end

  def down
    # Disable it but don't delete it since there might be sites using it
    Empty.find_by_name('prerelease').update(enabled: false)

    # Re-enable the old preview I guess
    Empty.find_by_name('tw5-json-store-test').update(enabled: true)
  end

end
