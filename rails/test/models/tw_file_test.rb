
class TwFileTest < ActiveSupport::TestCase

  MINIMAL_VALID = %{
    <html><head><meta name="application-name" content="TiddlyWiki">
    <meta name="tiddlywiki-version" content="5.1.24-prerelease"></head>
    <body><div id="storeArea"></div></body></html>}.freeze

  MINIMAL_ENCRYPTED = %{
    <html><head><meta name="application-name" content="TiddlyWiki">
    <meta name="tiddlywiki-version" content="5.1.24-prerelease"></head>
    <body><pre id="encryptedStoreArea"></pre></body></html>}.freeze

  CLASSIC_VALID = %{
    <html><head><script id="versionArea">title: "TiddlyWiki", major: 2, minor: 9, revision: 2</script>
    </head><body><div id="storeArea"></div></body></html>}.freeze

  test "adding a tiddler" do
    tw = TwFile.new(MINIMAL_VALID)
    tw.write_tiddlers('foo' => 'bar')

    assert_match '<div id="storeArea"><div title="foo"><pre>bar</pre></div></div>', tw.to_html
    assert_equal 'bar', tw.tiddler_content('foo')
    assert_equal 'bar', TwFile.new(tw.to_html).tiddler_content('foo')

    # For an encrypted TiddlyWiki we can't do anything
  end

  test "tiddlyhost mods for tw5" do
    ThFile.from_empty(:tw5).apply_tiddlyhost_mods('coolsite').tap do |tw|
      {
        '$:/UploadURL' => 'http://coolsite.example.com',
        '$:/UploadWithUrlOnly' => 'yes',
        '$:/config/AutoSave' => 'no',

      }.each do |tiddler_name, expected_content|
        assert_equal expected_content, tw.tiddler_content(tiddler_name)
      end

      assert_equal 'coolsite', tw.get_site_name
    end

    ThFile.from_empty(:tw5).apply_tiddlyhost_mods('coolsite', for_download: true).tap do |tw|
      {
        '$:/UploadURL' => '',
        '$:/UploadWithUrlOnly' => 'yes',
        '$:/config/AutoSave' => 'no',

      }.each do |tiddler_name, expected_content|
        assert_equal expected_content, tw.tiddler_content(tiddler_name)
      end

      # We can't get the name without $:/UploadURL...
      assert_nil tw.get_site_name
    end
  end

  test "tiddlyhost mods for classic" do
    ThFile.from_empty(:classic).apply_tiddlyhost_mods('coolsite').tap do |tw|
      [
        ['ThostUploadPlugin', false, "bidix.initOption('txtThostSiteName','coolsite');"],
        ['ThostUploadPlugin', false, "bidix.thostUpload.uploadChanges('#{Settings.subdomain_site_url("' + siteName + '")}');"],
        ['ThostUploadPlugin', false, "config.macros.thostUpload = {"],
        ['TiddlyHost', true, "is a hosting service for ~TiddlyWiki"],

      ].each do |tiddler_name, shadow, include_string|
        tiddler_content = tw.tiddler_content(tiddler_name, shadow)
        assert_includes tiddler_content, include_string
      end

      assert_equal 'coolsite', tw.get_site_name
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
      MINIMAL_ENCRYPTED,
      CLASSIC_VALID,

    ].each do |content|
      tw_file = TwFile.new(content)
      assert tw_file.looks_valid?

      # Some extra sanity checks
      assert tw_file.tiddlywiki_title.present?
      assert tw_file.tiddlywiki_version.present?
      assert_equal tw_file.is_classic?, tw_file.tiddlywiki_title_classic.present?
      assert_equal tw_file.is_classic?, tw_file.tiddlywiki_version_classic.present?
      assert_equal tw_file.is_tw5?, tw_file.tiddlywiki_title_tw5.present?
      assert_equal tw_file.is_tw5?, tw_file.tiddlywiki_version_tw5.present?
    end

    # Invalid files
    [
      ['Area', 'Aria'],
      ['TiddlyWiki', 'HackyWiki'],
      ['application-name', 'app-name', true],

    ].each do |match, replace, skip_classic|
      [
        MINIMAL_VALID,
        MINIMAL_ENCRYPTED,
        (CLASSIC_VALID unless skip_classic),

      ].compact.each do |content|
        refute TwFile.new(content.sub(match, replace)).looks_valid?
      end
    end

    # Garbage data
    refute TwFile.new(File.read("#{Rails.root}/app/assets/images/favicon.ico")).looks_valid?

  end

end
