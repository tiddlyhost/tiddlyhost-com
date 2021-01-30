
class TiddlywikiEmpty
  DEFAULT = 'tw5'

  def self.empty_path(empty_type=DEFAULT)
    "#{Rails.root}/empties/#{empty_type}.html"
  end

  def self.tiddler_div_helper(title, content)
    %{<div title="#{title}"><pre>#{content}</pre></div>}
  end

  def self.modified_empty(site_name, empty_type=DEFAULT)
    # Read in the raw empty file
    doc = Nokogiri::HTML(File.read(self.empty_path(empty_type)))

    store_area = doc.at('div#storeArea')

    {
      # TiddlyWiki will POST to this url using code in core/modules/savers/upload.js
      "$:/UploadURL" => Settings.subdomain_site_url(site_name),

      # Set this otherwise TiddlyWiki won't consider upload.js usable unless there
      # is a username and password present.
      "$:/UploadWithUrlOnly" => "yes",

      # Autosave is nice, but I'm thinking we should start with it off to generate
      # a little less traffic.
      "$:/config/AutoSave" => "no",

    }.each do |title, content|
      store_area << tiddler_div_helper(title, content)
    end

    doc.to_html
  end

end
