
class TwFileTest < ActiveSupport::TestCase

  test "adding a tiddler" do
    tw = TwFile.new('<html><body><div id="storeArea"></div></body></html>')
    tw.write_tiddlers('foo' => 'bar')

    assert_match '<div id="storeArea"><div title="foo"><pre>bar</pre></div></div>', tw.to_html
    assert_equal 'bar', tw.tiddler_content('foo')
    assert_equal 'bar', TwFile.new(tw.to_html).tiddler_content('foo')
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

end
