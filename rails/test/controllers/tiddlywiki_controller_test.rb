
require "test_helper"

class TiddlywikiControllerTest < ActionDispatch::IntegrationTest

  setup do
    @site = new_site_helper(name: 'foo', tiddlers: {
      'MyTiddler' => 'Hi there', 'Foo' => 'Bar', 'Baz' => '123' })

    host! "#{@site.name}.#{Settings.main_site_host}"
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
          "$:/core", "$:/isEncrypted",
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
    get url
    assert_response :success
    assert_equal tid, response.body
  end

  test "text/:title.tid for non-existent tiddler" do
    assert_tid_not_found('/text/Bananas.tid')
  end

  def assert_tid_not_found(url)
    get url
    assert_response :not_found
    assert_equal '', response.body
  end

  test "public site" do
    [nil, :mary, :bobby].each do |username|
      fetch_site_as_user(username: username, expected_status: 200)
    end
  end

  test "private site" do
    @site.update!(is_private: true)

    {nil=>401, mary: 403, bobby: 200}.each do |username, expected_status|
      fetch_site_as_user(username: username, expected_status: expected_status)
    end
  end

  def fetch_site_as_user(username:, expected_status:)
    user = User.where(username: username).first
    sign_in user if user

    get '/'
    assert_response expected_status

    if expected_status == 200
      th_file = ThFile.new(response.body)

      # Sanity checks
      assert_equal 'foo', th_file.get_site_name
      assert_equal 'Bar', th_file.tiddler_content('Foo')
      assert_equal '123', th_file.tiddler_content('Baz')

      # Status tiddlers when signed in
      is_owner = (user == @site.user)
      assert_equal(is_owner ? 'yes' : 'no', th_file.tiddler_content('$:/status/IsLoggedIn'))
      assert_equal(is_owner ? 'bobby' : '', th_file.tiddler_content('$:/status/UserName'))

      th_file
    end
  end

end
