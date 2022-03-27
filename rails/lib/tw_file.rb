
class TwFile

  module TiddlerDiv
    def self.from_fields(fields, tw_doc)
      fields.stringify_keys!
      text = fields.delete('text')

      Nokogiri::XML::Node.new('div', tw_doc) do |div|
        # Add the attributes to the div
        fields.each { |k, v| div[k] = v }

        # Add the tiddler text inside a pre element
        inner_pre = div.add_child(Nokogiri::XML::Node.new('pre', tw_doc))
        inner_pre.content = text

      end
    end

    def self.to_fields(div, skinny: false)
      return nil unless div

      # div.to_a is a list of attr/value pairs
      fields = Hash[div.to_a]

      # The tiddler text is inside a pre element
      fields.merge!('text' => div.at_xpath('pre').content) unless skinny
      fields
    end

  end

  def initialize(html_content)
    @doc = Nokogiri::HTML(html_content) do |config|
      config.options |= Nokogiri::XML::ParseOptions::HUGE
    end
  end

  def self.from_file(file_name)
    self.new(File.read(file_name))
  end

  # Presumably parsing the entire TW as a Nokogiri document is quite
  # heavy on memory resources. Provide a way to find the TW version
  # without doing that.
  #
  def self.light_get_version(html_content)
    # For TW5
    match = html_content.match(/^<meta name="tiddlywiki-version" content="([a-zA-Z0-9\-\._]+)"/m)
    return match[1] if match

    # For classic
    match = html_content.match(
      /^var version = { title: "TiddlyWiki", major: (\d+), minor: (\d+), revision: (\d+),/m)
    return match[1..3].join(".") if match
  end

  # We can't be certain, but we can sanity check a few things to
  # confirm that it at least looks like a legitimate TiddlyWiki
  #
  def looks_valid?
      # The application name is present
      tiddlywiki_title == 'TiddlyWiki' &&
        # Has one or other store divs but not both
        (store.present? ^ encrypted_store.present?) &&
        # We're able to extract a tiddlywiki version
        tiddlywiki_version.present?
  end

  def is_classic?
    tiddlywiki_version_classic.present?
  end

  def is_tw5?
    !is_classic?
  end

  def json_store?
    json_stores.present?
  end

  def get_meta(name)
    doc.at_xpath("/html/head/meta[@name='#{name}']/@content").try(:to_s)
  end

  def tiddlywiki_version
    tiddlywiki_version_tw5 || tiddlywiki_version_classic
  end

  def tiddlywiki_title
    tiddlywiki_title_tw5 || tiddlywiki_title_classic
  end

  def tiddlywiki_version_tw5
    get_meta('tiddlywiki-version')
  end

  def tiddlywiki_title_tw5
    get_meta('application-name')
  end

  def tiddlywiki_version_area
    doc.at_xpath("/html/head/script[@id='versionArea']").presence
  end

  def tiddlywiki_version_classic
    match = tiddlywiki_version_area.try(:text).try(:match, /major: (\d+), minor: (\d+), revision: (\d+)/).presence
    "#{match[1]}.#{match[2]}.#{match[3]}" if match
  end

  def tiddlywiki_title_classic
    match = tiddlywiki_version_area.try(:text).try(:match, /title: "(\w+)"/).presence
    match[1] if match
  end

  def encrypted?
    encrypted_store.present?
  end

  def to_html
    doc.to_html
  end

  # ** Methods from here down are useless for encrypted TiddlyWikis **

  def write_tiddlers(tiddlers, shadow: false)
    if json_store?
      # Assume we're using TW 5.2 and later
      append_json_store(tiddlers)

    else
      # Assume we're using TW 5.1.x or earlier
      tiddlers.each do |title, data|
        insert_or_replace(title, data, shadow: shadow)
      end

    end

    # For chaining method calls
    self
  end

  def write_shadow_tiddlers(tiddlers)
    write_tiddlers(tiddlers, shadow: true)
  end

  def tiddler_data(title, shadow: false)
    if json_store?
      tiddler_data_from_json(include_system: true)[title]
    else
      TiddlerDiv.to_fields(tiddler(title, shadow: shadow))
    end
  end

  def tiddler_content(title, shadow: false)
    tiddler_data(title, shadow: shadow).try(:[], 'text')
  end

  def shadow_tiddler_content(title)
    tiddler_content(title, shadow: true)
  end

  def tiddlers_data(include_system: false, skinny: false)
    return [] if encrypted?

    if json_store?
      tiddler_data_from_json(include_system: include_system, skinny: skinny).values

    else
      store.xpath('div').map do |t|
        next unless include_system || !t.attr('title').start_with?('$:/')
        TiddlerDiv.to_fields(t, skinny: skinny)
      end.compact

    end
  end

  private

  attr_reader :doc

  # Should be present for TW5 5.2 and later unless the site is encrypted.
  # Generally there is just one, but because TW will happily read from
  # multiple of these, we'll support that too and store this as a list.
  #
  def json_stores
    @_json_stores ||= doc.xpath("/html/body/script[@class='tiddlywiki-tiddler-store']")
  end

  # Should be present for both TW5 and Classic.
  # For 5.2 and later it's there also for backwards compatibility, but it will be empty.
  #
  def store
    (@_stores ||= doc.xpath("/html/body/div[@id='storeArea']")).first
  end

  # Present for encrypted TW5 files only, (even if they are 5.2 and later)
  #
  def encrypted_store
    (@_encrypted_stores ||= doc.xpath("/html/body/pre[@id='encryptedStoreArea']")).first
  end

  # Present for Classic only
  #
  def shadow_store
    (@_shadow_stores ||= doc.xpath("/html/body/div[@id='shadowArea']")).first
  end

  # Insert tiddlers by inserting or replacing divs inside the storeArea div.
  # For TW versions 5.1.x and earlier.
  #
  def insert_or_replace(title, data, shadow: false)
    return if encrypted?

    tiddler_div = create_tiddler_div(title, data)

    if existing_tiddler = tiddler(title, shadow: shadow)
      existing_tiddler.replace(tiddler_div)
    else
      choose_store(shadow: shadow) << tiddler_div
    end
  end

  # Insert tiddlers by creating a new script element with json inside it.
  # For TW versions 5.2 and later.
  #
  # It works because multiple store areas will be read in order, so tiddlers
  # we create here will have precedence over their namesakes in the main store area.
  # (The idea is that this should be easier and takes less memory resources than
  # loading, modifying and writing to the main store area.)
  #
  def append_json_store(tiddlers)
    # Convert tiddler data from a hash into an array of hashes,
    # and make sure the title is included
    tiddlers = tiddlers.map do |title, fields|
      fields = { text: fields } if fields.is_a?(String)
      fields[:title] = title
      fields
    end

    # Create new script element
    new_store_node = Nokogiri::XML::Node.new('script', doc) do |node|
      node['class'] = 'tiddlywiki-tiddler-store'
      node['type'] = 'application/json'
      node.content = tiddlers.to_json
    end

    # Insert it after the others
    json_stores.last.add_next_sibling(new_store_node)

    # Clear these to ensure the tiddler data will be refreshed
    @_json_stores = nil
    @_tiddler_data_from_json = nil
  end

  # For easy lookups we'll convert the tiddler data from a list into a
  # hash, where the keys will be the tiddler titles. Also, if we use a
  # hash then there's no need to worry about duplicates. The later one will
  # take precedence, which should match how TiddlyWiki does it.
  #
  def tiddler_data_from_json(include_system: false, skinny: false)
    # Cache it so we don't have to rebuild it more than once
    @_tiddler_data_from_json ||= begin
      # Iterate over all the store nodes and merge the results
      json_stores.inject({}) do |all_tiddlers, store_node|
        tiddler_list = JSON.load(store_node.content)
        tiddler_hash = Hash[ tiddler_list.map{ |t| [t['title'], t] } ]
        all_tiddlers.merge(tiddler_hash)
      end
    end

    # Return early if there's no need for further filtering
    return @_tiddler_data_from_json if include_system && !skinny

    # Otherwise, deal with the filtering as required.
    # Todo: Consider how to do this in a more memory efficient way.
    Hash[@_tiddler_data_from_json.map do |title, fields|
      # Skip the text field for skinny results
      use_fields = skinny ? fields.except('text') : fields
      # Skip the system tiddlers maybe
      include_system || !title.start_with?('$:/') ? [title, use_fields] : nil
    end.compact]
  end

  def tiddler(title, shadow: false)
    return if encrypted?

    # TODO: See how this works for titles with quotes in them
    tiddler_divs = choose_store(shadow: shadow).xpath("div[@title='#{title}']")
    raise 'Multiple tiddlers found!' if tiddler_divs.length > 1
    tiddler_divs.first
  end

  def choose_store(shadow: false)
    shadow ? shadow_store : store
  end

  def shadow_tiddler(title)
    tiddler(title, shadow: true)
  end

  def create_tiddler_div(title, fields)
    fields = { text: fields } if fields.is_a?(String)
    TiddlerDiv.from_fields(fields.merge(title: title), doc)
  end

end
