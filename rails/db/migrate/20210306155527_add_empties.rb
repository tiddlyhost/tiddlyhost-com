class AddEmpties < ActiveRecord::Migration[6.1]

  def up
    create_table :empties do |t|
      t.string :name
      t.string :title
      t.string :description
      t.boolean :enabled

      # Maybe we should put the content in the database too, but let's not do it now.
    end

    add_reference :sites, :empty, foreign_key: true

    Empty.create!([
      {
        name: 'tw5',
        title: 'TiddlyWiki',
        description: 'The current, modern version of TiddlyWiki, sometimes known as TiddlyWiki5.',
        enabled: true,
      },
      {
        name: 'classic',
        title: 'TiddlyWiki Classic',
        description: "'Classic' is the original, old version of TiddlyWiki that hasn't been updated much since 2011.",
        enabled: true,
      },
    ])

    # All sites so far were created with tw5
    Site.update_all(empty_id: Empty.find_by_name('tw5').id)

  end

  def down
    Site.update_all(empty_id: nil)
    remove_reference :sites, :empty, foreign_key: true
    drop_table :empties

  end

end
