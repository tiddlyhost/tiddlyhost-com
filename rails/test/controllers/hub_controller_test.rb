require "test_helper"

class HubControllerTest < ActionDispatch::IntegrationTest

  setup do
    @user = users(:bobby)
    @site = sites(:mysite)
  end

  test "hub index" do
    get '/hub'
    assert_response :success
    assert_site_visible

    # Make it not searchable
    @site.update(is_searchable: false)
    get '/hub'
    assert_response :success
    assert_site_not_visible
  end

  test "hub tag urls" do
    get '/hub/tag/bananas'
    assert_response :success
    assert_site_not_visible

    @site.tag_list.add('bananas')
    @site.save!
    get '/hub/tag/bananas'
    assert_response :success
    assert_site_visible
  end

  test "hub user urls" do
    get '/hub/user/bobby'
    assert_response :success
    assert_site_visible

    # Make it not searchable
    @site.update(is_searchable: false)
    get '/hub/user/bobby'
    assert_response :success
    assert_site_not_visible
  end

  test "a non existent user" do
    get '/hub/user/doesntexist'
    assert_redirected_to '/hub'
  end

  def assert_site_visible(site=@site)
    assert_select(".hub .site##{site.name}", count: 1)
  end

  def assert_site_not_visible(site=@site)
    assert_select(".hub .site##{site.name}", count: 0)
  end

end
