
class TwFile

  def initialize(html_content)
    @doc = Nokogiri::HTML(html_content) do |config|
      config.options |= Nokogiri::XML::ParseOptions::HUGE
    end

    @store = @doc.at_xpath("/html/body/div[@id='storeArea']")
  end

  def self.from_file(file_name)
    self.new(File.read(file_name))
  end

  def write_tiddlers(tiddlers)
    # For encryped TiddlyWikis div#storeArea doesn't exist.
    # Bail out quietly otherwise we'll throw errors.
    return self unless store.present?

    tiddlers.each do |title, content|
      insert_or_replace(title, content)
    end

    # For chaining method calls
    self
  end

  def tiddler_content(title)
    tiddler(title).try(:content)
  end

  def to_html
    doc.to_html
  end

  private

  attr_reader :doc, :store

  def insert_or_replace(title, content)
    tiddler_div = create_tiddler_div(title, content)

    if existing_tiddler = tiddler(title)
      existing_tiddler.replace(tiddler_div)
    else
      store << tiddler_div
    end
  end

  def tiddler(title)
    tiddler_divs = store.xpath("div[@title='#{title}']")
    raise 'Multiple tiddlers found!' if tiddler_divs.length > 1
    tiddler_divs.first
  end

  # We can return a string like this and it works fine:
  #   %{<div title="#{title}"><pre>#{content}</pre></div>}
  #
  # Doing it this way because I expect Nokogiri knows
  # better than I do how to do the escaping.
  #
  def create_tiddler_div(title, content)
    div = new_node('div')
    pre = div.add_child(new_node('pre'))
    div['title'] = title
    pre.content = content
    div
  end

  def new_node(elem_name)
    Nokogiri::XML::Node.new(elem_name, doc)
  end

end
