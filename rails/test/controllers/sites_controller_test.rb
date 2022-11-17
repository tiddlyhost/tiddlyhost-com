require "test_helper"

class SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = sites(:mysite)
    sign_in users(:bobby)
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

    assert_difference('Site.count') do
      post sites_url, params: { clone: 'mysite', site: { name: 'bar', is_private: "0" } }
      assert_redirected_to sites_url
    end

    cloned_site = Site.find_by_name('bar')
    assert_equal 'mary', cloned_site.user.username
    assert_equal @site.empty_id, cloned_site.empty_id
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

  test "should destroy site" do
    assert_difference('Site.count', -1) do
      delete site_url(@site)
    end

    assert_redirected_to sites_url
  end
end
