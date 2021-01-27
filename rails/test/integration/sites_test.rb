require "test_helper"

class SitesTest < CapybaraIntegrationTest
  setup do
    @user = users(:bobby)
    sign_in @user
  end

  test "visiting the index" do
    visit sites_url
    assert_selector "h1", text: "Your sites"
  end

  test "creating and viewing a site" do
    # Create a site
    visit sites_url
    click_on "Create site"
    fill_in "site_name", with: "bar"
    click_on "Create"

    # Confirm we are sent back to sites index
    assert_current_path '/sites'

    # The index now includes a link to the new site
    expected_url = "http://bar.example.com"
    assert_selector %{td a[href="#{expected_url}"]}

    # Visit the site and confirm it looks like a TiddlyWiki
    click_on "bar.example.com"

    # Sign out and confirm the site is still available
    sign_out @user
    visit expected_url
    assert_is_tiddlywiki

    # Make it a private site
    @user.reload.sites.last.update(is_private: true)

    # Confirm the private site is not available
    visit expected_url
    assert_is_404

    # ..unless we sign in again
    sign_in @user
    visit expected_url
    assert_is_tiddlywiki

    # Todo:
    # * The visit site testing should be split up and put elsewhere,
    #   probably home_controller_test.
    # * ..which would be easier if sites(:mysite).tiddlywiki_file.download
    #   returned something, stubbed or otherwise.
    # * Test coverage for saving a site.
  end

  test "updating a Site" do
    visit sites_url
    click_on "Settings", match: :first

    fill_in "Name", with: "foo"
    click_on "Update"

    # Back to the sites index after update
    assert_current_path '/sites'
    assert_selector "a", text: "foo.example.com"
  end

  def assert_is_tiddlywiki
    assert_equal 200, page.status_code
    assert_selector "meta[name=application-name][content=TiddlyWiki]", visible: false
  end

  def assert_is_404
    assert_equal 404, page.status_code
    assert_selector "title", text: "404 Not Found", visible: false
    assert_selector "h1", text: "Not found"
  end

end
