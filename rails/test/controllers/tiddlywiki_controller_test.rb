
require "test_helper"

class TiddlywikiControllerTest < ActionDispatch::IntegrationTest

  setup do
    @user = users(:bobby)
    @tiddlers = { 'MyTiddler'=>'Hi there', 'Foo'=>'Bar', 'Baz'=>'123' }
    @site = new_site_helper(user: @user, name: 'foo', tiddlers: @tiddlers)
    host! @site.host
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
    [ nil, :mary, :bobby ].each do |user|
      fetch_site_as_user(user: user, expected_status: 200)
    end
  end

  test "allow in iframe" do
    fetch_site_as_user
    assert_equal 'SAMEORIGIN', response.headers['X-Frame-Options']

    @site.update(allow_in_iframe: true)
    fetch_site_as_user
    refute response.headers.has_key?("X-Frame-Options")
  end

  test "private site" do
    @site.update!(is_private: true)

    { nil => 401, mary: 403, bobby: 200 }.each do |user, expected_status|
      fetch_site_as_user(user: user, expected_status: expected_status)
    end
  end

  test "saving" do
    # Test against different versions of TW since they'll all be present in prod
    for_all_empties do |empty_file, tw_kind, tw_version|

      site_name = "test-#{tw_version.gsub(/\./, '-')}"
      site_tiddlers = @tiddlers
      site_user = @user

      # Create new site
      site = new_site_helper(name: site_name, user: site_user,
        tiddlers: site_tiddlers, empty_content: File.read(empty_file))

      # So we can compare them later after the save happened
      original_blob_key = site.blob.key
      original_size = site.raw_byte_size

      # Sanity check
      assert_equal tw_kind, site.tw_kind
      assert_equal tw_version, site.tw_version
      assert_equal site_name, site.name
      fetch_site_as_user(user: site.user, site: site)

      # Prepare a modified version of the site, as though the
      # user added a tiddler, and write it to test/fixtures/files
      # since that's where fixture_file_upload will look for it
      #
      modified_tw_file = "#{Rails.root}/test/fixtures/files/index.html"
      File.write(modified_tw_file,
        site.th_file.write_tiddlers({'NewTiddler'=>'Hey now'}).to_html)

      # Now simulate a save
      upload_save_site_as_user(user: site.user, site: site, fixture_file: 'index.html')

      # Should see these fields are updated
      site.reload
      assert_not_equal original_blob_key, site.blob.key
      assert original_size < site.raw_byte_size
      assert_equal site_name, site.name
      assert_equal tw_version, site.tw_version

      # Confirm the site has the new tiddler
      assert_equal "Hey now", site.th_file.tiddler_content('NewTiddler')

      # Confirm it via http get
      th_file = fetch_site_as_user(user: site.user, site: site)
      assert_equal 'Hey now', th_file.tiddler_content('NewTiddler')

      if th_file.is_tw5?
        # Same thing again but using the put saver
        # (compatible with TW5 only)

        site.update(enable_put_saver: true)
        prev_blob_key = site.blob.key

        new_content = site.th_file.
          write_tiddlers({'NewTiddler'=>'Hi from put saver'}).to_html

        put_save_site_as_user(user: site.user, site: site, content: new_content)

        # Should see these fields are updated
        site.reload
        assert_not_equal original_blob_key, site.blob.key
        assert_not_equal prev_blob_key, site.blob.key
        assert original_size < site.raw_byte_size
        assert_equal site_name, site.name
        assert_equal tw_version, site.tw_version

        # Confirm the site has the new tiddler
        assert_equal "Hi from put saver", site.th_file.tiddler_content('NewTiddler')

        # Confirm it via http get
        th_file = fetch_site_as_user(user: site.user, site: site)
        assert_equal 'Hi from put saver', th_file.tiddler_content('NewTiddler')

      end

      # Clean up temporary file
      File.delete(modified_tw_file)
    end
  end

  test "upload save requires auth" do
    new_content = @site.th_file.
      write_tiddlers({'NewTiddler'=>'Hi'}).to_html

    modified_tw_file = "#{Rails.root}/test/fixtures/files/index.html"
    File.write(modified_tw_file, new_content)

    # It gives a 200 status even if it fails to save
    upload_save_site_as_user(user: users(:mary), site: @site, fixture_file: 'index.html',
      expected_status: 200, expect_success: false)

    assert_equal "If this is your site please log in at\nhttp://example.com and try again.\n",
      response.body
  end

  test "put save with etag check" do
    new_content = @site.th_file.
      write_tiddlers({'NewTiddler'=>'Hi'}).to_html

    @site.update(enable_put_saver: true)
    fetch_site_as_user
    etag = response.headers['ETag']
    assert_equal etag, @site.tw_etag

    put_save_site_as_user(user: @site.user, site: @site, content: new_content,
      headers: { 'If-Match' => etag }, expected_status: 204)

    assert_equal '', response.body
    assert_equal 'Hi', @site.th_file.tiddler_content('NewTiddler')
  end

  test "put save will not overwrite" do
    new_content = @site.th_file.
      write_tiddlers({'NewTiddler'=>'Hi'}).to_html
    @site.update(enable_put_saver: true)
    put_save_site_as_user(user: @site.user, site: @site, content: new_content,
      headers: { 'If-Match' => 'someotheretag' }, expected_status: 412)
    assert_equal(
      %{The site has been updated since you first loaded it. Saving now would cause those
      updates to be overwritten. Try reloading and then reapplying your changes.}.squish,
      response.body.squish)
  end

  test "put save requires auth" do
    new_content = @site.th_file.
      write_tiddlers({'NewTiddler'=>'Hi'}).to_html
    @site.update(enable_put_saver: true)
    put_save_site_as_user(user: users(:mary), site: @site, content: new_content,
      headers: { 'If-Match' => 'whatever' }, expected_status: 403)
    assert_equal(
      "If this is your site please log in at http://example.com and try again.", response.body)
  end

  def fetch_site_as_user(user: @user, site: @site, expected_status: 200)
    user = users(user) if user && !user.is_a?(User)

    host! site.host
    sign_in user if user

    get '/', headers: headers
    assert_response expected_status

    if expected_status == 200
      # ETag header is present and looks correct
      assert_equal site.tw_etag.encode('US-ASCII'), response.headers['ETag']

      th_file = ThFile.new(response.body)

      # Sanity checks
      if site.enable_put_saver?
        # Fixme: get_site_name can't work because $:/UploadURL isn't set
        #assert_equal site.name, th_file.get_site_name
        assert_equal '', th_file.tiddler_content('$:/UploadURL') if th_file.is_tw5?
      else
        assert_equal site.name, th_file.get_site_name
        assert_equal site.url, th_file.tiddler_content('$:/UploadURL') if th_file.is_tw5?
      end
      assert_equal 'Hi there', th_file.tiddler_content('MyTiddler')
      assert_equal 'Bar', th_file.tiddler_content('Foo')
      assert_equal '123', th_file.tiddler_content('Baz')

      if th_file.is_tw5?
        # Status tiddlers when signed in
        is_owner = (user == site.user)
        assert_equal(is_owner ? 'yes' : 'no', th_file.tiddler_content('$:/status/IsLoggedIn'))
        assert_equal(is_owner ? user.username : '', th_file.tiddler_content('$:/status/UserName'))
      end

      th_file
    end
  end

  def upload_save_site_as_user(site:, user:, fixture_file:, expected_status: 200, expect_success: true)
    host! site.host
    sign_in user

    file_upload = fixture_file_upload(fixture_file, 'text/html;charset=UTF-8')

    # The legacy UploadPlugin param is ignored, but put it here for extra realism
    post('/', params: {
      "UploadPlugin" => "backupDir=.;user=undefined;password=null;uploaddir=.;;\r\n",
      "userfile" => file_upload })

    assert_response expected_status

    if expect_success
      assert_equal "0 - OK\n", response.body
    end

    assert_equal "text/plain; charset=utf-8", response.headers["Content-Type"]
    # Todo maybe: Is there anything else worth asserting in the headers?
  end

  def put_save_site_as_user(site:, user:, content:, expected_status: 204, headers: {})
    host! site.host
    sign_in user

    put '/', params: content,
      headers: { 'Content-Type' => 'text/html;charset=UTF-8' }.merge(headers)

    assert_response expected_status
  end

end
