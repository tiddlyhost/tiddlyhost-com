
class TwFileTest < ActiveSupport::TestCase

  test "adding a tiddler" do
    tw = TwFile.new(minimal_html(:tw5))
    tw.write_tiddlers({'foo' => 'bar'})

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
        tiddler_content = tw.tiddler_content(tiddler_name, shadow: shadow)
        assert_includes tiddler_content, include_string
      end

      assert_equal 'coolsite', tw.get_site_name
    end
  end

  test "tiddlyhost mods do nothing for an encrypted tiddlywiki" do
    tw = ThFile.new(minimal_html(:encrypted))
    original_html = tw.to_html
    assert_equal original_html, tw.apply_tiddlyhost_mods('foo').to_html
  end

  test "tiddlywiki validation" do
    # Valid files
    %w[ tw5 encrypted classic classic_old ].each do |type|
      tw_file = TwFile.new(minimal_html(type))
      assert tw_file.looks_valid?

      assert tw_file.tiddlywiki_version.present?
    end

    # Invalid files
    [
      # Can't find store area
      [/[Ss]toreArea/, 'storeAria'],

      # Can't find a version (for TW5)
      [/"tiddlywiki-version"/, 'tiddly-version', :tw5],

      # Can't find version (for Classic)
      [/major:/, 'majer:', :classic],

    ].each do |match, replace, only|
      [
        (:tw5 unless only == :classic),
        (:encrypted unless only == :classic),
        (:classic unless only == :tw5),
        (:classic_old unless only == :tw5),

      ].compact.each do |type|
        refute TwFile.new(minimal_html(type).sub(match, replace)).looks_valid?
      end
    end

    # Garbage data
    refute TwFile.new(File.read("#{Rails.root}/app/assets/images/favicon.ico")).looks_valid?

  end

  def minimal_html(type)
    File.read("test/data/minimal_#{type}.html")
  end

end
