class AddFeatherwikiEmpty < ActiveRecord::Migration[6.1]

  def up
    (Empty.find_or_create_by(name: 'feather') do |e|
      e.title = 'Feather Wiki'
      e.description = 'A simple lightweight wiki with WYSIWYG amd Markdown support.'
      e.enabled = true
    end).update(enabled: true) # Make sure it's enabled in case you did a rollback
  end

  def down
    # Disable it but don't delete it since there might be sites using it
    Empty.find_by_name('feather').update(enabled: false)
  end

end
