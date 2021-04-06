
require "test_helper"

class TiddlywikiControllerTest < ActionDispatch::IntegrationTest

  setup do
    @site = new_site_helper(name: 'foo', tiddlers: {
      'MyTiddler' => 'Hi there', 'Foo' => 'Bar', 'Baz' => '123' })
  end

  test "tiddlers.json" do
    [
      { url: '/tiddlers.json',
        json: [
          {"title"=>"MyTiddler","text"=>"Hi there"},
          {"title"=>"Foo","text"=>"Bar"},
          {"title"=>"Baz","text"=>"123"} ] },

      { url: '/tiddlers.json?skinny=1',
        json: [ {"title"=>"MyTiddler"}, {"title"=>"Foo"}, {"title"=>"Baz"} ] },

      { url: '/tiddlers.json?skinny=1&include_system=1',
        titles: [
          "$:/config/OfficialPluginLibrary", "$:/core", "$:/isEncrypted",
          "$:/themes/tiddlywiki/snowwhite", "$:/themes/tiddlywiki/vanilla",
          "MyTiddler", "Foo", "Baz" ] },

      { url: '/tiddlers.json?title=Foo',
        json: [ {"title"=>"Foo","text"=>"Bar"} ] },

      { url: '/tiddlers.json?&skinny=1&title[]=Foo&title[]=Baz',
        json: [ {"title"=>"Foo"}, {"title"=>"Baz"} ] }

    ].each do |query|
      assert_expected_json(**query)
    end

  end

  def assert_expected_json(url:, json: nil, titles: nil)
    host! "foo.#{Settings.main_site_host}"
    get url
    assert_response :success
    assert_equal json, JSON.load(response.body) if json
    assert_equal titles, JSON.load(response.body).map{|v| v['title']} if titles
  end

  test "text/:title.tid" do
    [
      url: '/text/Foo.tid',
      tid: <<-EOT.strip_heredoc()
        title: Foo

        Bar
        EOT

    ].each do |query|
      assert_expected_tid(**query)
    end
  end

  def assert_expected_tid(url:, tid:)
    host! "foo.#{Settings.main_site_host}"
    get url
    assert_response :success
    assert_equal tid, response.body
  end

  test "text/:title.tid for non-existent tiddler" do
    assert_tid_not_found('/text/Bananas.tid')
  end

  def assert_tid_not_found(url)
    host! "foo.#{Settings.main_site_host}"
    get url
    assert_response :not_found
    assert_equal '', response.body
  end

end
