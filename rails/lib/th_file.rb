
class ThFile < TwFile

  DEFAULT = 'tw5'

  def self.empty_dir
    File.expand_path("#{__dir__}/../tw_content/empties")
  end

  def self.empty_path(empty_type=DEFAULT)
    "#{empty_dir}/#{empty_type}.html"
  end

  def self.empty_html(empty_type=DEFAULT)
    File.read(empty_path(empty_type))
  end

  def self.available_empties
    Dir.glob("#{empty_dir}/*.html").map{ |f| File.basename(f, '.html') }
  end

  def self.empty_versions
    Hash[ available_empties.map{ |e| [e, ThFile.from_empty(e).tiddlywiki_version] } ]
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
