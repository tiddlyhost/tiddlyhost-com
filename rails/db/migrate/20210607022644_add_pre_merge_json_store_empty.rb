class AddPreMergeJsonStoreEmpty < ActiveRecord::Migration[6.1]

  def up
    (Empty.find_or_create_by(name: 'tw5-json-store-test') do |e|
      e.title = 'New JSON store format pre-merge for test only'
      e.description = 'See https://github.com/simonbaird/tiddlyhost/issues/161'
      e.enabled = true
    end).update(enabled: true) # Make sure it's enabled in case you did a rollback
  end

  def down
    # Disable it but don't delete it since there might be sites using it
    Empty.find_by_name('tw5-json-store-test').update(enabled: false)
  end

end
