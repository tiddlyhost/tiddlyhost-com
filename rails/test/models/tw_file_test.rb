
class TwFileTest < ActiveSupport::TestCase

  MINIMAL_VALID = %{
    <html><head><meta name="application-name" content="TiddlyWiki"></head>
    <body><div id="storeArea"></div></body></html>}.freeze

  MINIMAL_ENCRYPTED = %{
    <html><head><meta name="application-name" content="TiddlyWiki"></head>
    <body><pre id="encryptedStoreArea"></pre></body></html>}.freeze

  test "adding a tiddler" do
    tw = TwFile.new(MINIMAL_VALID)
    tw.write_tiddlers('foo' => 'bar')

    assert_match '<div id="storeArea"><div title="foo"><pre>bar</pre></div></div>', tw.to_html
    assert_equal 'bar', tw.tiddler_content('foo')
    assert_equal 'bar', TwFile.new(tw.to_html).tiddler_content('foo')

    # For an encrypted TiddlyWiki we can't do anything
  end

  test "tiddlyhost mods" do
    ThFile.from_empty.apply_tiddlyhost_mods('coolsite').tap do |tw|
      {
        '$:/UploadURL' => 'http://coolsite.example.com',
        '$:/UploadWithUrlOnly' => 'yes',
        '$:/config/AutoSave' => 'no',

      }.each do |tiddler_name, expected_content|
        assert_equal expected_content, tw.tiddler_content(tiddler_name)
      end
    end
  end

  test "tiddlyhost mods do nothing for an encrypted tiddlywiki" do
    tw = ThFile.new(MINIMAL_ENCRYPTED)
    original_html = tw.to_html
    assert_equal original_html, tw.apply_tiddlyhost_mods('foo').to_html
  end

  test "tiddlywiki validation" do
    # Valid files
    [
      MINIMAL_VALID,
      MINIMAL_ENCRYPTED

    ].each do |content|
      assert TwFile.new(content).looks_valid?
    end

    # Invalid files
    [
      ['Area', 'Aria'],
      ['TiddlyWiki', 'HackyWiki'],
      ['application-name', 'app-name'],

    ].each do |match, replace|
      [MINIMAL_VALID, MINIMAL_ENCRYPTED].each do |content|
        refute TwFile.new(content.sub(match, replace)).looks_valid?
      end
    end

    # Garbage data
    refute TwFile.new(File.read("#{Rails.root}/app/assets/images/favicon.ico")).looks_valid?

  end

end
