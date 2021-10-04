class RenamePrereleaseEmpty < ActiveRecord::Migration[6.1]

  def up
    #
    # It used to say something about 5.2.0.
    # Now let's make it generic.
    #
    Empty.find_by_name('prerelease')&.update({
      title: "TiddlyWiki unstable prerelease version",
      description: "The latest prerelease version of TiddlyWiki 5. Use at your own risk.",
    })
  end

  def down
    # Don't worry about it...
  end

end
