require "test_helper"

class SitesTest < CapybaraIntegrationTest
  setup do
    @bobby = users(:bobby)
    @mary = users(:mary)
    sign_in @bobby
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

    # Sanity check the new site
    site = Site.last
    assert_equal 'bar', site.name
    assert site.is_public?
    refute site.is_searchable?
    assert site.looks_valid?

    # Visit the site and confirm it looks like a TiddlyWiki
    click_on "bar.example.com"
    assert_is_tiddlywiki

    # Sign out and confirm the site is still available
    # since it is a public site
    sign_out @bobby
    visit expected_url
    assert_is_tiddlywiki

    # Make it a private site
    @bobby.reload.sites.last.update(is_private: true)

    # Confirm the private site is not available
    visit expected_url
    assert_is_401
    assert_selector 'main p', text: "If this is your site"

    # ..unless we sign in again
    sign_in @bobby
    visit expected_url
    assert_is_tiddlywiki

    # Sign in as a different user
    # Site is still not available but the response is different
    sign_in @mary
    visit expected_url
    assert_is_403
    assert_selector 'main p', text: "This private site"

    # Todo:
    # * The visit site testing should be split up and put elsewhere,
    #   probably tiddlywiki_controller_test.
    # * ..which would be easier if sites(:mysite).tiddlywiki_file.download
    #   returned something, stubbed or otherwise.
    # * Test coverage for saving a site.
    # * Test coverage for saving a site with invalid content.
  end

  test "non-existent sites" do
    non_existent_site = 'http://bbar.example.com/'

    # You get a 404 when visiting a non-existent site
    visit non_existent_site
    assert_is_404
    assert_selector 'main p', text: "Visit Tiddlyhost"

    # ..whether you're signed in or not
    sign_out @bobby
    visit non_existent_site
    assert_is_404
    # ..but the text is slightly different
    assert_selector 'main p', text: "Sign up at Tiddlyhost"
  end

  test "updating site settings" do
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
    assert_selector "div#storeArea", visible: false
  end

  def assert_is_404
    assert_is_status(404, "Not Found")
  end

  def assert_is_401
    assert_is_status(401, "Forbidden")
  end

  def assert_is_403
    assert_is_status(403, "Unauthorized")
  end

  def assert_is_status(status_code, status_message)
    assert_equal status_code, page.status_code
    assert_selector "title", text: "#{status_code} #{status_message}", visible: false
    assert_selector "h1", text: "#{status_code} #{status_message}"
  end

end
