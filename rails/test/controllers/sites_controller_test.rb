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

  test "should create site" do
    assert_difference('Site.count') do
      post sites_url, params: { site: { name: 'foo', is_private: "0", empty_id: 1 } }
    end

    assert_redirected_to sites_url
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
