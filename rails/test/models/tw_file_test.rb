
class TwFileTest < ActiveSupport::TestCase

  test "adding a tiddler" do
    tw = TwFile.new(minimal_html(:tw5))
    tw.write_tiddlers({'foo' => 'bar'})

    assert_match '<div id="storeArea"><div title="foo"><pre>bar</pre></div></div>', tw.to_html
    assert_equal 'bar', tw.tiddler_content('foo')
    assert_equal 'bar', TwFile.new(tw.to_html).tiddler_content('foo')

    # For an encrypted TiddlyWiki we can't do anything
  end

  test "adding a tiddler with json script store" do
    tw = TwFile.new(minimal_html(:tw5_json))
    tw.write_tiddlers({'foo' => 'bar'})

    # We add tiddlers by appending a new script element
    assert_match '<script class="tiddlywiki-tiddler-store" type="application/json">[{"text":"bar","title":"foo"}]</script>', tw.to_html

    # The original script element store area is still there
    assert_match '<script class="tiddlywiki-tiddler-store" type="application/json">[]</script>', tw.to_html

    # The old storeArea is present also but with no content
    assert_match '<div id="storeArea"></div>', tw.to_html

    # So we notice the new content
    tw = TwFile.new(tw.to_html)

    assert_equal 'bar', tw.tiddler_content('foo')
    assert_equal([{'text'=>'bar','title'=>'foo'}], tw.tiddlers_data)
    assert_equal([{'title'=>'foo'}], tw.tiddlers_data(skinny: true))
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

    ThFile.from_empty(:tw5).apply_tiddlyhost_mods('coolsite', enable_put_saver: true).tap do |tw|
      {
        '$:/UploadURL' => '',
        '$:/UploadWithUrlOnly' => 'yes',
        '$:/config/AutoSave' => 'no',

      }.each do |tiddler_name, expected_content|
        assert_equal expected_content, tw.tiddler_content(tiddler_name)
      end

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
    %w[ tw5 encrypted classic ].each do |type|
      tw_file = TwFile.new(minimal_html(type))
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
        :tw5,
        :encrypted,
        (:classic unless skip_classic),

      ].compact.each do |type|
        refute TwFile.new(minimal_html(type).sub(match, replace)).looks_valid?
      end
    end

    # Garbage data
    refute TwFile.new(File.read("#{Rails.root}/app/assets/images/favicon.ico")).looks_valid?

  end

  test "light get version" do
    # Test with real empty files
    Dir["#{Rails.root}/tw_content/empties/*/*.html"].each do |empty_file|
      assert_equal(
        File.basename(empty_file, '.html'),
        TwFile.light_get_version(File.read(empty_file))
      )
    end

    # Test with the minimal test html files too I guess
    # (Maybe we can ditch these...)
    [
      [:tw5, '5.1.24-prerelease'],
      [:classic, '2.9.2'],
    ].each do |type, expected_version|
      assert_equal expected_version, TwFile.light_get_version(minimal_html(type))
    end
  end

  def minimal_html(type)
    File.read("test/data/minimal_#{type}.html")
  end

end
