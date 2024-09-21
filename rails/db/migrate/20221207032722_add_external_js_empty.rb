class AddExternalJsEmpty < ActiveRecord::Migration[6.1]
  def up
    data = YAML.load(<<-EOT.strip_heredoc)
      tw5x:
        title: TiddlyWiki External Core (Experimental)
        description: TiddlyWiki with the core javascript split into a separate file
        info_link: https://github.com/tiddlyhost/tiddlyhost-com/issues/171
        tooltip: >-
          Use with caution. With the core javascript in a separate, cacheable
          file the main file is smaller which makes loading and saving faster.
          The downside is the TiddlyWiki becomes less self-contained, since it
          won't work if the core javascript file is not accessible.
        display_order: 45
        enabled: true
    EOT

    data.each do |empty_name, fields|
      Empty.find_or_create_by(name: empty_name).update(fields)
    end
  end

  def down
    # Disable it but don't delete it since there might be sites using it
    Empty.find_by_name('tw5x').update(enabled: false)
  end
end
