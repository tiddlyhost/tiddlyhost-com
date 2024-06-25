# frozen_string_literal: true

require "test_helper"

class SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = sites(:mysite)
    @user = users(:bobby)
    sign_in @user
  end

  test "should get index" do
    get sites_url
    assert_response :success
  end

  test "should get new" do
    get new_site_url
    assert_response :success
  end

  test "should create and also clone site" do
    assert_difference('Site.count') do
      post sites_url, params: { site: { name: 'foo', is_private: "0", empty_id: 1 } }
      assert_redirected_to sites_url
    end

    # Smoke test
    new_site = Site.find_by_name('foo')
    assert_equal new_site, Site.last
    assert_match "Copyright (c) 2004-2007, Jeremy Ruston", new_site.file_download[0..2000]
    assert new_site.is_public?
    assert_equal 1, new_site.empty_id

    # Tweak the content so we can check the clone really happen
    new_site.content_upload(new_site.file_download.gsub("Jeremy", "Jermolene"))

    assert_difference('Site.count') do
      post sites_url, params: { clone: new_site.name, site: { name: 'bar', is_private: "0", empty_id: 1 } }
      assert_redirected_to sites_url
    end

    cloned_site = Site.find_by_name('bar')
    assert_equal new_site, cloned_site.cloned_from
    assert cloned_site.is_public?

    # Cloning your own site doesn't bump the clone count
    assert_equal 0, new_site.clone_count

    # Confirm the content came from the site that was cloned
    assert_match "Copyright (c) 2004-2007, Jermolene Ruston", cloned_site.file_download[0..2000]

    # See also test/integration/sites_test.rb
  end

  test "cant clone someone elses site" do
    assert_equal 'bobby', @site.user.username
    assert_equal false, @site.allow_public_clone?
    sign_in users(:mary)

    assert_no_difference('Site.count') do
      e = assert_raises(ActiveRecord::RecordNotFound) do
        # 'mysite' is owned by bobby
        post sites_url, params: { clone: 'mysite', site: { name: 'bar', is_private: "0" } }
      end
      # Todo maybe: Could give a more specific error message on disallowed clone attempts
      assert_equal "Couldn't find Empty without an ID", e.to_s
    end
  end

  test "can clone someone elses site if they allow it" do
    @site.content_upload("some content")
    @site.update(allow_public_clone: true)
    sign_in users(:mary)

    assert_equal 0, @site.clone_count
    assert_difference('Site.count') do
      post sites_url, params: { clone: 'mysite', site: { name: 'bar', is_private: "0" } }
      assert_redirected_to sites_url
    end

    cloned_site = Site.find_by_name('bar')
    assert_equal 'mary', cloned_site.user.username
    assert_equal @site.empty_id, cloned_site.empty_id
    assert_equal 1, @site.reload.clone_count
    assert_equal "some content", cloned_site.file_download
  end

  test "should show site" do
    get site_url(@site)
    assert_response :success
  end

  test "should get edit" do
    get edit_site_url(@site)
    assert_response :success
  end

  test "should update site" do
    patch site_url(@site), params: { site: { name: @site.name, is_private: "1" } }
    assert_redirected_to sites_url
  end

  test "uploads" do
    # Just so we can also confirm the save history is preserved when uploading
    @site.content_upload("hey")
    assert_nil @site.reload.tw_kind
    assert_equal 1, @site.saved_version_count

    # For something to upload, let's use a feather wiki empty
    file_to_upload = fixture_file_upload(
      "#{Rails.root}/tw_content/empties/feather.html", "text/html;charset=UTF-8")

    # Do the upload
    assert_enqueued_with(job: PruneAttachmentsJob) do
      patch upload_site_url(@site), params: { site: { tiddlywiki_file: file_to_upload } }
    end
    assert_redirected_to sites_url

    # Smoke test
    assert_equal "feather", @site.reload.tw_kind
    assert_equal 2, @site.saved_version_count
  end

  test "should destroy site" do
    assert_difference('Site.count', -1) do
      delete site_url(@site)
    end

    assert_redirected_to sites_url
  end

  test "site history access" do
    @site.content_upload("hey")

    Settings::Features.stub(:site_history_enabled?, false) do
      Settings::Features.stub(:site_history_preview_enabled?, false) do
        # Can't access
        get history_site_url(@site)
        assert_response :not_found
      end

      Settings::Features.stub(:site_history_preview_enabled?, true) do
        get history_site_url(@site)
        assert_response :success
      end
    end

    Settings::Features.stub(:site_history_enabled?, true) do
      get history_site_url(@site)
      assert_response :success
    end
  end

  def get_blob_ids(site)
    site.saved_content_files.order("created_at DESC").pluck(:blob_id)
  end

  test "site history" do
    @user.update(user_type: UserType.superuser)
    @site.content_upload("hey1")
    @site.content_upload("hey2")
    @site.content_upload("hey3")
    assert_equal "hey3", @site.file_download

    blob_ids = get_blob_ids(@site)
    assert_equal 3, blob_ids.count

    get history_site_url(@site)
    assert_response :success

    Settings::Features.stub(:site_history_enabled?, false) do
      # Restore an old version when feature is not enabled
      post "/sites/#{@site.id}/restore_version/#{blob_ids.last}"
      assert_response :not_found
    end

    # Restore an old version
    post "/sites/#{@site.id}/restore_version/#{blob_ids.last}"
    assert_redirected_to history_site_url(@site)

    # Confirm the site was updated
    assert_equal "hey1", @site.reload.file_download
    blob_ids = get_blob_ids(@site)
    assert_equal 4, blob_ids.count

    # Discard an old version
    post "/sites/#{@site.id}/discard_version/#{blob_ids.last}"
    assert_redirected_to history_site_url(@site)

    # Confirm the last blob was removed
    new_blob_ids = get_blob_ids(@site)
    assert_equal 3, new_blob_ids.count
    assert_equal blob_ids[0..-2], new_blob_ids
  end

end
