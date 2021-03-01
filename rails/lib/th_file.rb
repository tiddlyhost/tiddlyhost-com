
class ThFile < TwFile

  DEFAULT = 'tw5'
  def self.empty_path(empty_type=DEFAULT)
    "#{Rails.root}/empties/#{empty_type}.html"
  end

  def self.empty_html(empty_type=DEFAULT)
    File.read(empty_path(empty_type))
  end

  def self.from_empty(empty_type=DEFAULT)
    from_file(empty_path(empty_type))
  end

  def apply_tiddlyhost_mods(site_name)
    write_tiddlers({
      # TiddlyWiki will POST to this url using code in core/modules/savers/upload.js
      '$:/UploadURL' => Settings.subdomain_site_url(site_name),

      # Set this otherwise TiddlyWiki won't consider upload.js usable unless there
      # is a username and password present.
      '$:/UploadWithUrlOnly' => 'yes',

      # Autosave is nice, but I'm thinking we should start with it off to generate
      # a little less traffic.
      '$:/config/AutoSave' => 'no',
    })
  end

  def get_site_name
    # (It would be nice if there was a better way to do this.)
    tiddler_content('$:/UploadURL').match(%r{//([a-z-]+)\.}).try(:[], 1)
  end

end
